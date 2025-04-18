`timescale 1ns / 1ps

module AES_CMAC#(
    parameter C = 128'h00000000000000000000000000000087 // Full 128-bit constant
)
(   
    input clk,
    input reset,
    input wire [31:0] len,
    input wire [127:0] messIn,
    input wire [127:0] cmacIn,
    output [127:0] encrypted,
    output reg cmacDone,
    output reg [8:0] messAddra,
    output reg [8:0] cmacAddra,
    output reg [127:0] tag,
    output wire [5:0] cntr
   );

    wire [(128*11)-1:0] fullkeys;
    wire [127:0] key128 = 128'h000102030405060708090a0b0c0d0e0f;
    reg [127:0] in; 
//    wire [127:0] messIn;
//    wire [127:0] cmacIn; 
    reg L_ready, tag_updated;
    reg compute = 1'b0;
    wire [127:0] out_X;
    reg done_out, final_tag;
    reg [127:0] cmacReg;
    reg [1:0] calc;
    
    reg messDone;
    reg bufFlg;
    reg [127:0] X;
//    reg [8:0] messAddra;
//    reg [8:0] cmacAddra;
    
    reg [127:0] xin2;
    wire [127:0] out;
    reg [127:0] L;
    wire [127:0] K1,K2;
    wire flag;
    reg [31:0] size;
    
    reg [1:0] rem;
    wire [3:0] keyRnd;
    reg rst,sflg;
    
    wire [127:0] sIn;
    wire [127:0] sOut,sIn1,addrkIn,key,x1,x2,xorOut;
    wire [31:0] rot,xorIn1,xorIn2;
//    reg [127:0] tag;
    subBytes s(sIn,sOut);
    addRoundKey xorCalc (x1, xorOut, x2);
    keyExpansion ke (clk,reset,key128, fullkeys,keyRnd,rot,sOut,xorIn1,xorIn2,xorOut);
    
    assign sIn=sflg?sIn1:{{96{1'b0}},rot};
    assign x1=sflg?addrkIn:{{96{1'b0}},xorIn1};
    assign x2=sflg?key:{{96{1'b0}},xorIn2};
    
//    ram BRAM1 (clk, 1'b1,1'b1,1'b0,1'b0, messAddra,cmacAddra, dia, messIn,dib,cmacIn);
    AES_Encrypt inst1 (clk,rst, in, fullkeys, encrypted,flag,cntr,sIn1,sOut,addrkIn,key,xorOut);

//    always @(posedge clk) begin
    assign K1 = (L << 1) ^ (L[127] ? C : 0); 
    assign K2 = (K1 << 1) ^ (K1[127] ? C : 0); 
//    end
    
    always@(posedge clk) begin
//        $display("x1:%h x2:%h xOut:%h",x1,x2,xorOut);
        if(reset) begin
            messAddra<=9'b0; 
            cmacAddra<=9'b0;
            messDone<=1'b0;
            cmacDone<=1'b0;
            cmacReg<=128'b0;
            bufFlg<=1'b1;
            calc<=2'd0;
            size<=len/128;
            rst<=1'b1;
            sflg<=1'b0;
        end  
        else if(keyRnd>=11) begin
            sflg<=1'b1;
            if(rst==0)begin
                    if(messDone==1'b0) begin

                    if(messAddra>=size) begin
                        if(cntr==45) begin
                            in<=cmacIn^cmacReg;
                            messDone<=1'b1;
                            cmacReg<=encrypted; 
                        end
                    end
                    else if(messAddra%3==0) begin                        
                        in<=messIn;
                        messAddra<=messAddra+1;
                        cmacReg<=encrypted;

                    end
                    else if(messAddra%3==1) begin
                        if(bufFlg==1'b1)begin
                            bufFlg<=1'b0;
                            in<=messIn;
                        end
                        else begin 
                            messAddra<=messAddra+1;
                            in<=cmacIn^cmacReg;
                            bufFlg<=1'b1;
                        end

                    end
                    else if(messAddra%3==2)begin
                        if(flag) begin
                            messAddra<=messAddra+1;
                            cmacAddra<=cmacAddra+1;
                        end

                        in<=messIn;
                    end
                end
                 else if(cmacDone==1'b0) begin
                     if(cntr==3 & calc==2'd0) begin
                        calc<=2'd1;
                        in<=128'd0;
                     end
                     if(cntr==46 & calc==2'd1)begin
                        L<=encrypted;
                        calc<=2'd2;
                    end
                     if(cntr==46) in<=cmacIn^cmacReg;
                     if(cntr==45) cmacReg<=encrypted;
                     
                     if(flag)begin
                        cmacAddra<=cmacAddra+1;
                    end
                    
                     if(cmacAddra==size-1) begin
    
                            if(cntr==46)begin
    //                            $display("rem: ",len%16'd128);
                                if(len%128) in<=cmacReg^cmacIn^K2;
                                else in<=cmacReg^cmacIn^K1;          
                            end
                            if(flag) tag<=encrypted;
                        end
                        if(cmacAddra>=size) begin
                            if(cntr==46) begin
                                
                                cmacDone<=1'b1;
                            end
                        end
                 end
             end
            rst<=1'b0;
        end
//        $display("keyRnd:%d cntr:%d flg:%b calc:%d L1:%h messAddra:%d cmacAddra:%d messIn:%h cmacIn:%h in:%h cmacReg:%h encrypted:%h bufFlg:%d messDone:%b cmacDone:%b tag:%h",keyRnd,cntr,flag,calc, L,messAddra,cmacAddra,messIn,cmacIn,in,cmacReg,encrypted,bufFlg,messDone,cmacDone,tag);
//        $display("%h %h %h %h %h %h %h %h %h %h %h",fullkeys[(128*11-1)-:128],fullkeys[(128*10-1)-:128],fullkeys[(128*9-1)-:128],fullkeys[(128*8-1)-:128],fullkeys[(128*7-1)-:128],fullkeys[(128*6-1)-:128],fullkeys[(128*5-1)-:128],fullkeys[(128*4-1)-:128],fullkeys[(128*3-1)-:128],fullkeys[(128*2-1)-:128],fullkeys[(128*1-1)-:128]);
    end

endmodule