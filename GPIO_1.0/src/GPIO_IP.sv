`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/13 10:18:32
// Design Name: 
// Module Name: GPIO_IP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module GPIO_IP(
    output logic [7:0] idata,
    input logic [7:0] odata,
    input logic [7:0] mode, //input or output
    inout logic [7:0] io
    );

    genvar i;
    generate
        for(i=0;i<8;i++) begin
            assign io[i] = (mode[i]) ? odata[i] : 1'bz; //3-state buffer 
            assign idata[i] = (~mode[i]) ? io[i] : 1'bz; 
        end
    endgenerate

    // initial에서는 걍 박아도 되는데 generate에서는 assign 
endmodule

module AXI_INTERFACE_GPIO (
    input logic ACLK,
    input logic ARESETn,
    //Write transaction. Aw channel
    input logic [3:0] AWADDR,
    input logic AWVALID,
    output logic AWREADY,
    //WRITE transaction, Wchannel
    input logic [31:0] WDATA,
    input logic WVALID,
    output logic WREADY,
    //WRITE transaction, Bchannel
    output logic [3:0] BRESP,
    output logic BVALID,
    input logic BREADY,
    //READ transaction, ARchannel
    input logic ARVALID,
    input logic [3:0] ARADDR,
    output logic ARREADY,
    // READ transcation , Rchannel
    output logic [31:0] RDATA,
    input logic RVALID,
    output logic RREADY,
    output logic [1:0] RRESP, 

    //GPIO
    inout logic [7:0] IOPORT
    );
    logic [7:0] idata;

    logic [31:0] slv_reg0, // moder
    slv_reg1, // odr
    slv_reg2; //idr
    // slv_reg3; 

    assign slv_reg2 = {{24{1'b0}},idata};
   //AW 
   typedef enum {
        AW_IDLE_S,
        AW_READY_S
      } aw_state_e;
   //W
   typedef enum {
        W_IDLE_S,
        W_READY_S
      } w_state_e;
   //AW

    typedef enum {
        B_IDLE_S,
        B_VALID_S
      } b_state_e;  
// read transaction

      typedef enum {
        AR_IDLE_S,
        AR_READY_S
      } ar_state_e;

    typedef enum {
        R_IDLE_S,
        R_READY_S
    } r_state_e;

      aw_state_e aw_state, aw_state_next;
      w_state_e w_state, w_state_next;
      b_state_e b_state, b_state_next;
      ar_state_e ar_state, ar_state_next;
      r_state_e r_state, r_state_next;

      logic [3:0] aw_addr_reg, aw_addr_next;
      logic [3:0] ar_addr_reg, ar_addr_next;
    //   logic [31:0] w_data_reg, w_data_next;
   //W

      always_ff @( posedge ACLK ) begin : blockName
        if(!ARESETn) begin
            aw_state <= AW_IDLE_S;
            w_state <= W_IDLE_S;
            aw_addr_reg <= 0;
            ar_addr_reg <= 0;
            b_state <= B_IDLE_S;
            ar_state <= AR_IDLE_S;
            r_state <= R_IDLE_S;
            // w_data_reg <= 0;
        end
        else begin
            aw_state <= aw_state_next;
            aw_addr_reg <= aw_addr_next;
            w_state <= w_state_next;
            b_state <= b_state_next;
            ar_addr_reg <= ar_addr_next;
            ar_state <= ar_state_next;
            r_state <= r_state_next;
            // w_data_reg <= w_data_next;
        end
      end

      always_comb begin : AWchannel
        aw_state_next = aw_state;
        AWREADY = 0;
        case(aw_state)
        AW_IDLE_S: begin
            AWREADY = 0;
            if(AWVALID) begin
                aw_state_next = AW_READY_S;
                aw_addr_next = AWADDR; //래칭하기! //해야되나? 
            end
        end
        AW_READY_S: begin
            AWREADY = 1'b1;
            if(AWVALID && AWREADY) begin
                aw_state_next = AW_IDLE_S;
            end
        end
        endcase
      end

       always_comb begin : Wchannel
        w_state_next = w_state;
        WREADY = 0;
        // w_data_next = w_data_reg;

        case(w_state)
        W_IDLE_S: begin
            WREADY = 0;
            if(AWVALID) begin
                w_state_next = W_READY_S;
                // w_data_next = WDATA; //WADDR/ WDATA 동시에 보내도록 만들어 놓음 
            end
        end
        W_READY_S: begin
            case(aw_addr_reg[3:0])
            0: slv_reg0 = WDATA;
            4: slv_reg1 = WDATA;
            // 8: slv_reg2 = WDATA; //읽기전용용
            // 12: slv_reg3 = WDATA;
            endcase
            WREADY = 1'b1;
            if(WVALID) begin
                w_state_next = W_IDLE_S;
            end
        end
        endcase
      end


        always_comb begin : Bchannel
        b_state_next = b_state;
        BVALID = 0;
        case(b_state)
        B_IDLE_S: begin
            BVALID = 0;
            if(WVALID && WREADY) b_state_next = B_VALID_S;
        end
        B_VALID_S: begin
            BVALID = 1'b1;
            BRESP = 2'b00;
            if(BVALID && BREADY) b_state_next = B_IDLE_S;
        end
        endcase
      end
      // read transaction

        always_comb begin : ARchannel
        ar_state_next = ar_state;
        ARREADY = 0;
        case(ar_state)
        AR_IDLE_S: begin
            ARREADY = 0;
            if(ARVALID) begin
                ar_state_next = AR_READY_S;
                ar_addr_next = ARADDR; //래칭하기! //해야되나? 
            end
        end
        AR_READY_S: begin
            ARREADY = 1'b1;
            if(ARVALID && ARREADY) begin
                ar_state_next = AR_IDLE_S;
            end
        end
        endcase
      end

        always_comb begin : Rchannel
        r_state_next = r_state;
        RREADY = 0;
        case(r_state)
        R_IDLE_S: begin
            RREADY = 0;
            if(RVALID) r_state_next = R_READY_S;
        end
        R_READY_S: begin
            RREADY = 1'b1;
            RRESP = 2'b00;
            case(ar_addr_reg)
            0: RDATA = slv_reg0;
            4: RDATA = slv_reg1;
            8: RDATA = slv_reg2;
            // 12:RDATA = slv_reg3;
            endcase
            if(RVALID && RREADY) r_state_next = R_IDLE_S;
        end
        endcase
      end
GPIO_IP u_GPIO(
    .idata(idata),
    .odata(slv_reg1[7:0]),
    .mode(slv_reg0[7:0]), //input or output
    .io(IOPORT)
    );


endmodule