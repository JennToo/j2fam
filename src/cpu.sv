`define OP_NOP 8'hEA
`define OP_LDA_IMM 8'hA9
`define OP_LDA_ZP 8'hA5
`define OP_LDA_ZPX 8'hB5
`define OP_LDA_ABS 8'hAD
`define OP_LDX_IMM 8'hA2
`define OP_LDX_ZP 8'hA6
`define OP_LDY_IMM 8'hA0
`define OP_LDY_ZP 8'hA4
`define OP_ADC_IMM 8'h69
`define OP_JMP_ABS 8'h4C
`define OP_STA_ZP 8'h85

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
  logic [7:0] next_status;
  logic new_carry;

  // Control signals
  logic accumulator_to_alu_input_a;
  logic accumulator_to_data;
  logic adder_hold_to_accumulator;
  logic adder_hold_to_address_low;
  logic alu_result_to_adder_hold;
  logic alu_status_to_status;
  logic bus_read;
  logic bus_write;
  logic data_status_to_status;
  logic data_to_accumulator;
  logic data_to_adder_hold;
  logic data_to_address_high;
  logic data_to_address_low;
  logic data_to_alu_input_b;
  logic data_to_index_x;
  logic data_to_index_y;
  logic data_to_next_instruction;
  logic data_to_pc_high;
  logic data_to_pc_low;
  logic fd_to_address_low;
  logic ff_to_address_high;
  logic increment_pc_to_address;
  logic increment_pc_to_pc;
  logic pc_low_to_address_low;
  logic x_to_alu_input_a;
  logic zero_to_address_high;

  always_comb begin
    // Control signals
    accumulator_to_alu_input_a = 0;
    accumulator_to_data = 0;
    adder_hold_to_accumulator = 0;
    adder_hold_to_address_low = 0;
    alu_result_to_adder_hold = 0;
    alu_status_to_status = 0;
    bus_read = 0;
    bus_write = 0;
    data_status_to_status = 0;
    data_to_accumulator = 0;
    data_to_adder_hold = 0;
    data_to_address_high = 0;
    data_to_address_low = 0;
    data_to_alu_input_b = 0;
    data_to_index_x = 0;
    data_to_index_y = 0;
    data_to_next_instruction = 0;
    data_to_pc_high = 0;
    data_to_pc_low = 0;
    fd_to_address_low = 0;
    ff_to_address_high = 0;
    increment_pc_to_address = 0;
    increment_pc_to_pc = 0;
    pc_low_to_address_low = 0;
    x_to_alu_input_a = 0;
    zero_to_address_high = 0;

    next_instruction_stage = instruction_stage;

    case (instruction_stage)
      0: begin
        if (data_valid_i) begin
          next_instruction_stage = 1;
          increment_pc_to_pc = 1;
          increment_pc_to_address = 1;
          bus_read = 1;
          data_to_next_instruction = 1;
        end

        case (current_instruction)
          `OP_ADC_IMM: begin
            adder_hold_to_accumulator = 1;
          end

          default: begin
          end
        endcase
      end

      1: begin
        case (current_instruction)
          `OP_NOP: begin
            next_instruction_stage = 0;
          end
          `OP_LDA_IMM, `OP_LDX_IMM, `OP_LDY_IMM: begin
            if (data_valid_i) begin
              next_instruction_stage = 0;
              increment_pc_to_pc = 1;
              increment_pc_to_address = 1;
              bus_read = 1;
              data_status_to_status = 1;
              case (current_instruction)
                `OP_LDA_IMM: data_to_accumulator = 1;
                `OP_LDX_IMM: data_to_index_x = 1;
                `OP_LDY_IMM: data_to_index_y = 1;
                default: begin
                end
              endcase
            end
          end
          `OP_STA_ZP: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              data_to_address_low = 1;
              zero_to_address_high = 1;
              accumulator_to_data = 1;
              bus_write = 1;
            end
          end
          `OP_ADC_IMM: begin
            if (data_valid_i) begin
              next_instruction_stage = 0;
              increment_pc_to_pc = 1;
              increment_pc_to_address = 1;
              bus_read = 1;
              accumulator_to_alu_input_a = 1;
              data_to_alu_input_b = 1;
              alu_result_to_adder_hold = 1;
            end
          end
          `OP_LDA_ZP, `OP_LDX_ZP, `OP_LDY_ZP: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              zero_to_address_high = 1;
              data_to_address_low = 1;
              bus_read = 1;
            end
          end
          `OP_LDA_ZPX: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              x_to_alu_input_a = 1;
              data_to_alu_input_b = 1;
              alu_result_to_adder_hold = 1;
            end
          end
          `OP_LDA_ABS: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              data_to_adder_hold = 1;
              increment_pc_to_address = 1;
              bus_read = 1;
            end
          end
          `OP_JMP_ABS: begin
            if (data_valid_i) begin
              next_instruction_stage = 2;
              data_to_pc_low = 1;
              increment_pc_to_address = 1;
              bus_read = 1;
            end
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
              `OP_LDA_ZP: data_to_accumulator = 1;
              `OP_LDX_ZP: data_to_index_x = 1;
              `OP_LDY_ZP: data_to_index_y = 1;
              default: begin
              end
            endcase
          end
          `OP_LDA_ZPX: begin
            next_instruction_stage = 3;
            adder_hold_to_address_low = 1;
            zero_to_address_high = 1;
            bus_read = 1;
          end
          `OP_STA_ZP: begin
            // It's not clear why we need to wait here. It's possible the
            // original hardware can't setup a write to the data register on
            // the same cycle that it's sending that data to the low address
            // register. We have no such weakness
            next_instruction_stage = 3;
          end
          `OP_LDA_ABS: begin
            if (data_valid_i) begin
              next_instruction_stage = 3;
              adder_hold_to_address_low = 1;
              data_to_address_high = 1;
              increment_pc_to_pc = 1;
              increment_pc_to_address = 1;
              bus_read = 1;
            end
          end
          `OP_JMP_ABS: begin
            if (data_valid_i) begin
              next_instruction_stage = 0;
              data_to_pc_high = 1;
              pc_low_to_address_low = 1;
              data_to_address_high = 1;
              bus_read = 1;
            end
          end
          default begin
          end
        endcase
      end

      3: begin
        case (current_instruction)
          `OP_STA_ZP: begin
            next_instruction_stage = 0;
            increment_pc_to_pc = 1;
            increment_pc_to_address = 1;
            bus_read = 1;
          end
          `OP_LDA_ABS: begin
            if (data_valid_i) begin
              next_instruction_stage = 0;
              increment_pc_to_pc = 1;
              increment_pc_to_address = 1;
              data_to_accumulator = 1;
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
              `OP_LDA_ZPX: data_to_accumulator = 1;
              default begin
              end
            endcase
          end

          default begin
          end
        endcase
      end

      `RESET_STAGE_1: begin
        if (data_valid_i == 1) begin
          next_instruction_stage = `RESET_STAGE_2;
          data_to_pc_low = 1;
          ff_to_address_high = 1;
          fd_to_address_low = 1;
          bus_read = 1;
        end
      end

      `RESET_STAGE_2: begin
        if (data_valid_i == 1) begin
          next_instruction_stage = 0;
          data_to_pc_high = 1;
          pc_low_to_address_low = 1;
          data_to_address_high = 1;
          bus_read = 1;
        end
      end
      default begin
      end
    endcase
  end


  // Data status flags computation
  always_comb begin
    data_status = 0;
    data_status[`STATUS_ZERO] = (data_i == 0);
    data_status[`STATUS_NEGATIVE] = data_i[7];
  end

  // ALU
  always_comb begin
    alu_input_a = 0;
    alu_input_b = 0;
    if (accumulator_to_alu_input_a) begin
      alu_input_a = accumulator;
    end
    if (x_to_alu_input_a) begin
      alu_input_a = index_x;
    end
    if (data_to_alu_input_b) begin
      alu_input_b = data_i;
    end

    {new_carry, alu_result} = alu_input_a + alu_input_b + {8'b0, status[`STATUS_CARRY]};
    alu_result_status = status;
    alu_result_status[`STATUS_CARRY] = new_carry;
    alu_result_status[`STATUS_NEGATIVE] = alu_result[7];
    alu_result_status[`STATUS_ZERO] = (alu_result == 0);
    // TODO
    alu_result_status[`STATUS_OVERFLOW] = 0;
  end

  // Register write sorting
  always_comb begin
    next_accumulator = accumulator;
    next_index_x = index_x;
    next_index_y = index_y;
    next_status = status;
    next_address_low = address_low;
    next_address_high = address_high;
    next_program_counter_low = program_counter_low;
    next_program_counter_high = program_counter_high;
    next_adder_hold = adder_hold;
    next_instruction = current_instruction;
    next_output_data = data_output;

    if (data_to_accumulator) begin
      next_accumulator = data_i;
    end
    if (data_to_index_x) begin
      next_index_x = data_i;
    end
    if (data_to_index_y) begin
      next_index_y = data_i;
    end
    if (zero_to_address_high) begin
      next_address_high = 0;
    end
    if (data_to_address_low) begin
      next_address_low = data_i;
    end
    if (data_to_address_high) begin
      next_address_high = data_i;
    end
    if (alu_status_to_status) begin
      next_status = alu_result_status;
    end
    if (data_status_to_status) begin
      next_status = data_status;
    end
    if (data_to_pc_low) begin
      next_program_counter_low = data_i;
    end
    if (data_to_pc_high) begin
      next_program_counter_high = data_i;
    end
    if (pc_low_to_address_low) begin
      next_address_low = program_counter_low;
    end
    if (increment_pc_to_address) begin
      next_address_low  = incremented_program_counter[7:0];
      next_address_high = incremented_program_counter[15:8];
    end
    if (increment_pc_to_pc) begin
      next_program_counter_low  = incremented_program_counter[7:0];
      next_program_counter_high = incremented_program_counter[15:8];
    end
    if (ff_to_address_high) begin
      next_address_high = 8'hFF;
    end
    if (fd_to_address_low) begin
      next_address_low = 8'hFD;
    end
    if (data_to_adder_hold) begin
      next_adder_hold = data_i;
    end
    if (adder_hold_to_address_low) begin
      next_address_low = adder_hold;
    end
    if (data_to_next_instruction) begin
      next_instruction = data_i;
    end
    if (adder_hold_to_accumulator) begin
      next_accumulator = adder_hold;
    end
    if (alu_result_to_adder_hold) begin
      next_adder_hold = alu_result;
    end
    if (accumulator_to_data) begin
      next_output_data = accumulator;
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
      status <= 8'bXX1101XX;
    end else if (clock_ready == 1) begin
      current_instruction <= next_instruction;
      instruction_stage <= next_instruction_stage;
      accumulator <= next_accumulator;
      index_x <= next_index_x;
      index_y <= next_index_y;
      status <= next_status;
      program_counter_low <= next_program_counter_low;
      program_counter_high <= next_program_counter_high;
      address_low <= next_address_low;
      address_high <= next_address_high;
      bus_read_o <= bus_read;
      bus_write_o <= bus_write;
      adder_hold <= next_adder_hold;
      data_output <= next_output_data;
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
