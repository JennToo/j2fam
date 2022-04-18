`define OP_NOP 8'hEA
`define OP_LDA_IMM 8'hA9
`define OP_LDA_ZP 8'hA5
`define OP_LDX_IMM 8'hA2
`define OP_LDX_ZP 8'hA6
`define OP_LDY_IMM 8'hA0
`define OP_LDY_ZP 8'hA4

module cpu #(
    parameter unsigned CLOCK_DIVIDER = 12
) (
    input logic clock_i,
    input logic reset_i,

    input logic [7:0] data_i,
    input logic data_valid_i,

`ifdef SIMULATION
    output logic clock_ready_o,
    output logic [15:0] program_counter_o,
    output logic [7:0] accumulator_o,
    output logic [7:0] index_x_o,
    output logic [7:0] index_y_o,
    output logic [7:0] status_o,
    output logic [7:0] stack_pointer_o,
`endif  // SIMULATION

    output logic [7:0] data_o,
    output logic [15:0] address_o,
    output logic address_valid_o,
    output logic data_valid_o
);

  logic [7:0] clock_divider;

  logic clock_ready;
  always_ff @(posedge clock_i) begin
    if (reset_i == 1) begin
      clock_ready   <= 0;
      clock_divider <= 0;
    end else if (clock_divider == CLOCK_DIVIDER - 1) begin
      clock_divider <= 0;
      clock_ready   <= 1;
    end else begin
      clock_divider <= clock_divider + 1;
      clock_ready   <= 0;
    end
  end

  `define RESET_STAGE_1 6
  `define RESET_STAGE_2 7

  logic [15:0] program_counter;
  logic [ 7:0] accumulator;
  logic [ 7:0] index_x;
  logic [ 7:0] index_y;
  logic [ 7:0] status;
  logic [ 7:0] stack_pointer;

  logic [ 2:0] instruction_stage;
  logic [ 7:0] current_instruction;

  logic [15:0] incremented_program_counter;
  assign incremented_program_counter = program_counter + 1;

  logic [7:0] read_instruction;
  logic [2:0] next_instruction_stage;
  logic increment_and_read_program_counter;
  logic read_data_zeropage;
  logic data_to_accumulator;
  logic data_to_index_x;
  logic data_to_index_y;

  always_comb begin
    // Prevent inferring latches. TODO: Is there a better way to do this?
    next_instruction_stage = instruction_stage;
    increment_and_read_program_counter = 0;
    data_to_accumulator = 0;
    data_to_index_x = 0;
    data_to_index_y = 0;
    read_data_zeropage = 0;

    if (instruction_stage == 0) begin
      read_instruction = data_i;
    end else begin
      read_instruction = current_instruction;
    end

    case (instruction_stage)
      0: begin
        next_instruction_stage = 1;

        if (data_valid_i) begin
          case (read_instruction)
            `OP_LDA_IMM, `OP_LDX_IMM, `OP_LDY_IMM, `OP_LDA_ZP, `OP_LDX_ZP, `OP_LDY_ZP: begin
              increment_and_read_program_counter = 1;
            end

            default begin
            end
          endcase
        end
      end

      1: begin
        case (read_instruction)
          `OP_NOP: begin
            next_instruction_stage = 0;
            increment_and_read_program_counter = 1;
          end
          `OP_LDA_IMM, `OP_LDX_IMM, `OP_LDY_IMM: begin
            if (data_valid_i) begin
              next_instruction_stage = 0;
              increment_and_read_program_counter = 1;
              case (current_instruction)
                `OP_LDA_IMM: data_to_accumulator = 1;
                `OP_LDX_IMM: data_to_index_x = 1;
                `OP_LDY_IMM: data_to_index_y = 1;
                default: begin
                end
              endcase
            end
          end
          `OP_LDA_ZP, `OP_LDX_ZP, `OP_LDY_ZP: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              read_data_zeropage = 1;
            end
          end
          default begin
          end
        endcase
      end

      2: begin
        case (read_instruction)
          `OP_LDA_ZP, `OP_LDX_ZP, `OP_LDY_ZP: begin
            next_instruction_stage = 0;
            increment_and_read_program_counter = 1;
            case (current_instruction)
              `OP_LDA_ZP: data_to_accumulator = 1;
              `OP_LDX_ZP: data_to_index_x = 1;
              `OP_LDY_ZP: data_to_index_y = 1;
              default: begin
              end
            endcase
          end
          default begin
          end
        endcase
      end

      default begin
      end
    endcase
  end


  always_ff @(posedge clock_i) begin
    if (reset_i == 1) begin
      instruction_stage <= `RESET_STAGE_1;
      address_valid_o <= 1;
      address_o <= 16'hFFFC;
      accumulator <= 0;
      index_x <= 0;
      index_y <= 0;
      stack_pointer <= 0;
      // Based on W65C02, but close enough for now
      status <= 8'bXX1101XX;
    end else if (clock_ready == 1) begin
      current_instruction <= read_instruction;
      instruction_stage   <= next_instruction_stage;
      if (increment_and_read_program_counter) begin
        program_counter <= incremented_program_counter;
        address_o <= incremented_program_counter;
        address_valid_o <= 1;
      end
      if (read_data_zeropage) begin
        address_o <= {8'b0, data_i};
        address_valid_o <= 1;
      end
      if (data_to_accumulator) accumulator <= data_i;
      if (data_to_index_x) index_x <= data_i;
      if (data_to_index_y) index_y <= data_i;

      case (instruction_stage)
        `RESET_STAGE_1: begin
          if (data_valid_i == 1) begin
            instruction_stage <= `RESET_STAGE_2;
            program_counter[7:0] <= data_i;
            address_o <= 16'hFFFD;
            address_valid_o <= 1;
          end
        end

        `RESET_STAGE_2: begin
          if (data_valid_i == 1) begin
            instruction_stage <= 0;
            program_counter[15:8] <= data_i;
            address_o <= {data_i, program_counter[7:0]};
            address_valid_o <= 1;
          end
        end

        default begin
        end
      endcase
    end
  end

`ifdef SIMULATION
  assign clock_ready_o = clock_ready;
  assign program_counter_o = program_counter;
  assign accumulator_o = accumulator;
  assign index_x_o = index_x;
  assign index_y_o = index_y;
  assign status_o = status;
  assign stack_pointer_o = stack_pointer;
`endif  // SIMULATION
endmodule : cpu
