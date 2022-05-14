`define OP_ADC_IMM 8'h69
`define OP_CLC 8'h18
`define OP_JMP_ABS 8'h4C
`define OP_LDA_ABS 8'hAD
`define OP_LDA_IDX 8'hA1
`define OP_LDA_IMM 8'hA9
`define OP_LDA_ZP 8'hA5
`define OP_LDA_ZPX 8'hB5
`define OP_LDX_IMM 8'hA2
`define OP_LDX_ZP 8'hA6
`define OP_LDY_IMM 8'hA0
`define OP_LDY_ZP 8'hA4
`define OP_NOP 8'hEA
`define OP_SBC_IMM 8'hE9
`define OP_SEC 8'h38
`define OP_STA_ZP 8'h85
`define OP_TAX 8'hAA
`define OP_TAY 8'hA8
`define OP_TSX 8'hBA
`define OP_TXA 8'h8A
`define OP_TXS 8'h9A
`define OP_TYA 8'h98

`define STATUS_ZERO 1
`define STATUS_NEGATIVE 7
`define STATUS_CARRY 0
`define STATUS_OVERFLOW 6

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
    output logic bus_read_o,
    output logic bus_write_o
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

  // "External" registers
  logic [ 7:0] accumulator;
  logic [ 7:0] index_x;
  logic [ 7:0] index_y;
  logic [ 7:0] program_counter_high;
  logic [ 7:0] program_counter_low;
  logic [ 7:0] stack_pointer;
  logic [ 7:0] status;

  // Internal registers
  logic [ 2:0] instruction_stage;
  logic [ 7:0] adder_hold;
  logic [ 7:0] address_high;
  logic [ 7:0] address_low;
  logic [ 7:0] current_instruction;
  logic [ 7:0] data_output;

  logic [15:0] incremented_program_counter;
  assign incremented_program_counter = {program_counter_high, program_counter_low} + 1;

  logic [2:0] next_instruction_stage;
  logic [7:0] alu_input_a;
  logic [7:0] alu_input_b;
  logic [7:0] alu_result;
  logic [7:0] alu_result_status;
  logic [7:0] data_status;
  logic [7:0] next_accumulator;
  logic [7:0] next_adder_hold;
  logic [7:0] next_address_high;
  logic [7:0] next_address_low;
  logic [7:0] next_index_x;
  logic [7:0] next_index_y;
  logic [7:0] next_instruction;
  logic [7:0] next_output_data;
  logic [7:0] next_program_counter_high;
  logic [7:0] next_program_counter_low;
  logic [7:0] next_stack_pointer;
  logic [7:0] next_status;
  logic new_carry;

  // Control signals
  logic alu_carry_flag;
  logic alu_invert_b;
  logic alu_result_to_adder_hold;
  logic alu_status_to_status;
  logic bus_read;
  logic bus_write;
  logic data_status_to_status;
  logic increment_pc_to_address;
  logic increment_pc_to_pc;

  always_comb begin
    next_accumulator = accumulator;
    next_adder_hold = adder_hold;
    next_address_high = address_high;
    next_address_low = address_low;
    next_index_x = index_x;
    next_index_y = index_y;
    next_instruction = current_instruction;
    next_output_data = data_output;
    next_program_counter_high = program_counter_high;
    next_program_counter_low = program_counter_low;
    next_stack_pointer = stack_pointer;
    next_status = status;
    next_instruction_stage = instruction_stage;

    // Control signals
    alu_invert_b = 0;
    alu_result_to_adder_hold = 0;
    alu_status_to_status = 0;
    bus_read = 0;
    bus_write = 0;
    data_status_to_status = 0;
    increment_pc_to_address = 0;
    increment_pc_to_pc = 0;

    alu_input_a = 0;
    alu_input_b = 0;

    case (instruction_stage)
      0: begin
        if (data_valid_i) begin
          next_instruction_stage = 1;
          next_instruction = data_i;
          case (data_i)
            `OP_NOP, `OP_TAX, `OP_TAY, `OP_TXA, `OP_TYA, `OP_TXS, `OP_TSX, `OP_SEC, `OP_CLC: begin
            end
            default begin
              increment_pc_to_pc = 1;
              increment_pc_to_address = 1;
              bus_read = 1;
            end
          endcase
        end

        case (current_instruction)
          `OP_ADC_IMM, `OP_SBC_IMM: begin
            next_accumulator = adder_hold;
          end

          default: begin
          end
        endcase
      end

      1: begin
        case (current_instruction)
          `OP_NOP: begin
            next_instruction_stage = 0;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
          end
          `OP_SEC: begin
            next_instruction_stage = 0;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
            next_status[`STATUS_CARRY] = 1;
          end
          `OP_CLC: begin
            next_instruction_stage = 0;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
            next_status[`STATUS_CARRY] = 0;
          end
          `OP_LDA_IMM, `OP_LDX_IMM, `OP_LDY_IMM: begin
            if (data_valid_i) begin
              next_instruction_stage = 0;
              increment_pc_to_pc = 1;
              increment_pc_to_address = 1;
              bus_read = 1;
              data_status_to_status = 1;
              case (current_instruction)
                `OP_LDA_IMM: next_accumulator = data_i;
                `OP_LDX_IMM: next_index_x = data_i;

                `OP_LDY_IMM: next_index_y = data_i;

                default: begin
                end
              endcase
            end
          end
          `OP_STA_ZP: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              next_address_low = data_i;
              next_address_high = 0;
              next_output_data = accumulator;
              bus_write = 1;
            end
          end
          `OP_ADC_IMM: begin
            if (data_valid_i) begin
              next_instruction_stage = 0;
              increment_pc_to_pc = 1;
              increment_pc_to_address = 1;
              bus_read = 1;
              alu_input_a = accumulator;
              alu_input_b = data_i;
              alu_result_to_adder_hold = 1;
              alu_status_to_status = 1;
            end
          end
          `OP_SBC_IMM: begin
            if (data_valid_i) begin
              next_instruction_stage = 0;
              increment_pc_to_pc = 1;
              increment_pc_to_address = 1;
              bus_read = 1;
              alu_input_a = accumulator;
              alu_input_b = data_i;
              alu_invert_b = 1;
              alu_result_to_adder_hold = 1;
            end
          end
          `OP_LDA_ZP, `OP_LDX_ZP, `OP_LDY_ZP: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              next_address_high = 0;
              next_address_low = data_i;
              bus_read = 1;
            end
          end
          `OP_LDA_ZPX, `OP_LDA_IDX: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              alu_input_a = index_x;
              alu_input_b = data_i;
              alu_result_to_adder_hold = 1;
            end
          end
          `OP_LDA_ABS: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              next_adder_hold = data_i;
              increment_pc_to_address = 1;
              bus_read = 1;
            end
          end
          `OP_JMP_ABS: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              next_program_counter_low = data_i;
              increment_pc_to_address = 1;
              bus_read = 1;
            end
          end
          `OP_TAX: begin
            next_instruction_stage = 0;
            next_index_x = accumulator;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
          end
          `OP_TAY: begin
            next_instruction_stage = 0;
            next_index_y = accumulator;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
          end
          `OP_TXA: begin
            next_instruction_stage = 0;
            next_accumulator = index_x;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
          end
          `OP_TYA: begin
            next_instruction_stage = 0;
            next_accumulator = index_y;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
          end
          `OP_TXS: begin
            next_instruction_stage = 0;
            next_stack_pointer = index_x;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
          end
          `OP_TSX: begin
            next_instruction_stage = 0;
            next_index_x = stack_pointer;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
          end

          default begin
          end
        endcase
      end

      2: begin
        case (current_instruction)
          `OP_LDA_ZP, `OP_LDX_ZP, `OP_LDY_ZP: begin
            next_instruction_stage = 0;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
            data_status_to_status = 1;
            case (current_instruction)
              `OP_LDA_ZP: next_accumulator = data_i;
              `OP_LDX_ZP: next_index_x = data_i;

              `OP_LDY_ZP: next_index_y = data_i;

              default: begin
              end
            endcase
          end
          `OP_LDA_ZPX: begin
            next_instruction_stage = 3;
            next_address_low = adder_hold;
            next_address_high = 0;
            bus_read = 1;
          end
          `OP_LDA_IDX: begin
            next_instruction_stage = 3;
            // Read low byte of indirect address
            next_address_low = adder_hold;
            next_address_high = 0;
            bus_read = 1;
            // Prepare for high byte access
            alu_input_b = 1;
            alu_input_a = adder_hold;
            alu_result_to_adder_hold = 1;
          end
          `OP_STA_ZP: begin
            next_instruction_stage = 0;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
          end
          `OP_LDA_ABS: begin
            if (data_valid_i) begin
              next_instruction_stage = 3;
              next_address_low = adder_hold;
              next_address_high = data_i;
              increment_pc_to_pc = 1;
              bus_read = 1;
            end
          end
          `OP_JMP_ABS: begin
            if (data_valid_i) begin
              next_instruction_stage = 0;
              next_program_counter_high = data_i;
              next_address_low = program_counter_low;
              next_address_high = data_i;
              bus_read = 1;
            end
          end
          default begin
          end
        endcase
      end

      3: begin
        case (current_instruction)
          `OP_LDA_ABS: begin
            if (data_valid_i) begin
              next_instruction_stage = 0;
              increment_pc_to_pc = 1;
              increment_pc_to_address = 1;
              next_accumulator = data_i;
              bus_read = 1;
            end
          end
          `OP_LDA_ZPX: begin
            next_instruction_stage = 0;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
            data_status_to_status = 1;
            case (current_instruction)
              `OP_LDA_ZPX: next_accumulator = data_i;

              default begin
              end
            endcase
          end
          `OP_LDA_IDX: begin
            next_instruction_stage = 4;
            // Read second byte of indirect address
            next_address_low = adder_hold;
            next_address_high = 0;
            bus_read = 1;
            // Save first byte of indirect address
            next_adder_hold = data_i;
          end

          default begin
          end
        endcase
      end

      4: begin
        case (current_instruction)
          `OP_LDA_IDX: begin
            next_instruction_stage = 5;
            next_address_low = adder_hold;
            next_address_high = data_i;
            bus_read = 1;
          end
          default begin
          end
        endcase
      end

      5: begin
        case (current_instruction)
          `OP_LDA_IDX: begin
            next_instruction_stage = 0;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
            next_accumulator = data_i;
          end
          default begin
          end
        endcase
      end

      `RESET_STAGE_1: begin
        if (data_valid_i == 1) begin
          next_instruction_stage = `RESET_STAGE_2;
          next_program_counter_low = data_i;
          next_address_high = 8'hFF;
          next_address_low = 8'hFD;
          bus_read = 1;
        end
      end

      `RESET_STAGE_2: begin
        if (data_valid_i == 1) begin
          next_instruction_stage = 0;
          next_program_counter_high = data_i;
          next_address_low = program_counter_low;
          next_address_high = data_i;
          bus_read = 1;
        end
      end
      default begin
      end
    endcase

    data_status = 0;
    data_status[`STATUS_ZERO] = (data_i == 0);
    data_status[`STATUS_NEGATIVE] = data_i[7];

    alu_carry_flag = status[`STATUS_CARRY];

    if (alu_invert_b) begin
      alu_input_b = ~alu_input_b;
      alu_carry_flag = ~alu_carry_flag;
    end

    {new_carry, alu_result} = {1'b0, alu_input_a} + {1'b0, alu_input_b} + {8'b0, alu_carry_flag};
    alu_result_status = status;
    alu_result_status[`STATUS_CARRY] = new_carry;
    alu_result_status[`STATUS_NEGATIVE] = alu_result[7];
    alu_result_status[`STATUS_ZERO] = (alu_result == 0);
    // TODO
    alu_result_status[`STATUS_OVERFLOW] = 0;

    if (alu_status_to_status) begin
      next_status = alu_result_status;
    end
    if (data_status_to_status) begin
      next_status = data_status;
    end
    if (increment_pc_to_address) begin
      next_address_low  = incremented_program_counter[7:0];
      next_address_high = incremented_program_counter[15:8];
    end
    if (increment_pc_to_pc) begin
      next_program_counter_low  = incremented_program_counter[7:0];
      next_program_counter_high = incremented_program_counter[15:8];
    end
    if (alu_result_to_adder_hold) begin
      next_adder_hold = alu_result;
    end
  end

  always_ff @(posedge clock_i) begin
    if (reset_i == 1) begin
      instruction_stage <= `RESET_STAGE_1;
      bus_read_o <= 1;
      address_low <= 8'hFC;
      address_high <= 8'hFF;
      accumulator <= 0;
      index_x <= 0;
      index_y <= 0;
      stack_pointer <= 0;
      // Based on W65C02, but close enough for now
      status <= 8'b00110100;
    end else if (clock_ready == 1) begin
      accumulator <= next_accumulator;
      adder_hold <= next_adder_hold;
      address_high <= next_address_high;
      address_low <= next_address_low;
      bus_read_o <= bus_read;
      bus_write_o <= bus_write;
      current_instruction <= next_instruction;
      data_output <= next_output_data;
      index_x <= next_index_x;
      index_y <= next_index_y;
      instruction_stage <= next_instruction_stage;
      program_counter_high <= next_program_counter_high;
      program_counter_low <= next_program_counter_low;
      stack_pointer <= next_stack_pointer;
      status <= next_status;
    end
  end

  assign address_o = {address_high, address_low};
  assign data_o = data_output;

`ifdef SIMULATION
  assign clock_ready_o = clock_ready;
  assign program_counter_o = {program_counter_high, program_counter_low};
  assign accumulator_o = accumulator;
  assign index_x_o = index_x;
  assign index_y_o = index_y;
  assign status_o = status;
  assign stack_pointer_o = stack_pointer;
`endif  // SIMULATION
endmodule : cpu
