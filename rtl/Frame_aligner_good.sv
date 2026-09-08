//--------------------------------------------------------------
// Frame Aligner - FSM Reference RTL
// Explicit FSM implementation of the original reference behavior.
//
// Legal headers:
//   Header 1: 0xAA -> 0xAF
//   Header 2: 0x55 -> 0xBA
//
// Frame:
//   2 header bytes + 10 payload bytes = 12 bytes
//--------------------------------------------------------------

module frame_aligner (
    input  logic       clk,
    input  logic [7:0] rx_data,
    input  logic       reset,

    output logic [3:0] fr_byte_position,
    output logic       frame_detect
);

    //----------------------------------------------------------
    // Legal header bytes
    //----------------------------------------------------------
    localparam logic [7:0] HEADER1_LSB = 8'hAA;
    localparam logic [7:0] HEADER1_MSB = 8'hAF;
    localparam logic [7:0] HEADER2_LSB = 8'h55;
    localparam logic [7:0] HEADER2_MSB = 8'hBA;

    //----------------------------------------------------------
    // FSM states
    //----------------------------------------------------------
    localparam logic [2:0] SEARCH_LSB   = 3'd0;
    localparam logic [2:0] CHECK_MSB    = 3'd1;
    localparam logic [2:0] GOOD_PAYLOAD = 3'd2;
    localparam logic [2:0] SYNC_LSB     = 3'd3;
    localparam logic [2:0] SYNC_MSB     = 3'd4;
    localparam logic [2:0] BAD_FRAME    = 3'd5;
    localparam logic [2:0] LOSS_DELAY   = 3'd6;

    logic [2:0] state;
    logic [2:0] next_state;

    //----------------------------------------------------------
    // Next values for registered outputs
    //----------------------------------------------------------
    logic [3:0] fr_byte_position_next;
    logic       frame_detect_next;

    //----------------------------------------------------------
    // Internal registers
    //----------------------------------------------------------

    // Expected MSB after AA or 55
    logic [7:0] expected_msb;
    logic [7:0] expected_msb_next;

    // Remaining payload bytes in a legal frame
    logic [3:0] payload_left;
    logic [3:0] payload_left_next;

    // Remaining bytes to ignore in a bad frame
    logic [3:0] bad_left;
    logic [3:0] bad_left_next;

    // Number of consecutive legal frames
    logic [1:0] good_frames;
    logic [1:0] good_frames_next;

    // Number of consecutive bad bytes while synchronized
    logic [5:0] bad_bytes;
    logic [5:0] bad_bytes_next;

    // Set after a legal header.
    // The frame is counted on Payload[0].
    logic good_pending;
    logic good_pending_next;


    //----------------------------------------------------------
    // Combinational next-state logic
    //----------------------------------------------------------
    always_comb begin

        //------------------------------------------------------
        // Default: hold current values
        //------------------------------------------------------
        next_state            = state;

        fr_byte_position_next = fr_byte_position;
        frame_detect_next     = frame_detect;

        expected_msb_next     = expected_msb;
        payload_left_next     = payload_left;
        bad_left_next         = bad_left;
        good_frames_next      = good_frames;
        bad_bytes_next        = bad_bytes;
        good_pending_next     = good_pending;

        //------------------------------------------------------
        // FSM
        //------------------------------------------------------
        case (state)

            //--------------------------------------------------
            // Not synchronized:
            // search every byte for AA or 55.
            //--------------------------------------------------
            SEARCH_LSB: begin

                fr_byte_position_next = 4'd0;
                good_pending_next     = 1'b0;

                if (rx_data == HEADER1_LSB) begin
                    expected_msb_next = HEADER1_MSB;
                    next_state        = CHECK_MSB;
                end
                else if (rx_data == HEADER2_LSB) begin
                    expected_msb_next = HEADER2_MSB;
                    next_state        = CHECK_MSB;
                end
                else begin
                    good_frames_next = 2'd0;
                end
            end


            //--------------------------------------------------
            // Not synchronized:
            // check the byte after AA/55.
            //
            // On mismatch, the current byte is checked again
            // as a possible new LSB. This keeps overlap support:
            //
            //   55 AA AF
            //      AA AF
            //
            //   AA 55 BA
            //      55 BA
            //--------------------------------------------------
            CHECK_MSB: begin

                if (rx_data == expected_msb) begin

                    // Legal header
                    fr_byte_position_next = 4'd1;
                    payload_left_next     = 4'd10;
                    good_pending_next     = 1'b1;
                    next_state            = GOOD_PAYLOAD;

                end
                else begin

                    // Bad MSB breaks the consecutive-good streak
                    good_frames_next      = 2'd0;
                    fr_byte_position_next = 4'd0;

                    // Re-check current byte as a new LSB
                    if (rx_data == HEADER1_LSB) begin
                        expected_msb_next = HEADER1_MSB;
                        next_state        = CHECK_MSB;
                    end
                    else if (rx_data == HEADER2_LSB) begin
                        expected_msb_next = HEADER2_MSB;
                        next_state        = CHECK_MSB;
                    end
                    else begin
                        next_state = SEARCH_LSB;
                    end
                end
            end


            //--------------------------------------------------
            // Legal frame payload.
            // Exactly 10 bytes are consumed.
            // Header-like data inside the payload is ignored.
            //--------------------------------------------------
            GOOD_PAYLOAD: begin

                //------------------------------------------------
                // Count the newly accepted frame on Payload[0].
                //
                // For first synchronization acquisition:
                // frame_detect remains 0 during Payload[0].
                // It becomes 1 after Payload[0], therefore
                // Payload[1] is the first sampled byte that sees
                // frame_detect == 1.
                //------------------------------------------------
                if ((payload_left == 4'd10) && good_pending) begin

                    good_pending_next = 1'b0;

                    if (good_frames < 2'd3)
                        good_frames_next = good_frames + 2'd1;

                    if (good_frames == 2'd2)
                        frame_detect_next = 1'b1;
                end

                // MSB is position 1, payload positions are 2..11
                fr_byte_position_next = fr_byte_position + 4'd1;

                if (payload_left == 4'd1) begin

                    payload_left_next = 4'd0;

                    if (frame_detect_next)
                        next_state = SYNC_LSB;
                    else
                        next_state = SEARCH_LSB;

                end
                else begin
                    payload_left_next = payload_left - 4'd1;
                end
            end


            //--------------------------------------------------
            // Synchronized:
            // fixed 12-byte frame boundary, check only LSB here.
            //--------------------------------------------------
            SYNC_LSB: begin

                fr_byte_position_next = 4'd0;

                if (rx_data == HEADER1_LSB) begin
                    expected_msb_next = HEADER1_MSB;
                    next_state        = SYNC_MSB;
                end
                else if (rx_data == HEADER2_LSB) begin
                    expected_msb_next = HEADER2_MSB;
                    next_state        = SYNC_MSB;
                end
                else begin

                    // Bad first header byte.
                    // This byte is byte #1 of a 12-byte bad frame.
                    good_frames_next = 2'd0;
                    bad_bytes_next   = bad_bytes + 6'd1;
                    bad_left_next    = 4'd11;
                    next_state       = BAD_FRAME;
                end
            end


            //--------------------------------------------------
            // Synchronized:
            // check MSB at the fixed frame boundary.
            //--------------------------------------------------
            SYNC_MSB: begin

                if (rx_data == expected_msb) begin

                    // Legal header
                    fr_byte_position_next = 4'd1;
                    payload_left_next     = 4'd10;
                    good_pending_next     = 1'b1;

                    // A legal frame breaks the bad-frame streak
                    bad_bytes_next        = 6'd0;

                    next_state            = GOOD_PAYLOAD;

                end
                else begin

                    // Bad MSB.
                    // LSB + MSB are already two bad bytes.
                    good_frames_next      = 2'd0;
                    fr_byte_position_next = 4'd0;

                    bad_bytes_next        = bad_bytes + 6'd2;
                    bad_left_next         = 4'd10;

                    next_state            = BAD_FRAME;
                end
            end


            //--------------------------------------------------
            // Bad frame while synchronized.
            //
            // Ignore all remaining bytes until the next fixed
            // 12-byte boundary. Do NOT search for headers here.
            //--------------------------------------------------
            BAD_FRAME: begin

                fr_byte_position_next = 4'd0;

                if (bad_left != 4'd0) begin

                    //------------------------------------------------
                    // The current byte is the 48th consecutive bad
                    // byte when:
                    //   bad_bytes == 47 before consuming it
                    // and it is the final byte of the 4th bad frame.
                    //
                    // Do not lower frame_detect in this cycle.
                    // Move to LOSS_DELAY instead.
                    //------------------------------------------------
                    if ((bad_left == 4'd1) &&
                        (bad_bytes == 6'd47)) begin

                        bad_bytes_next = 6'd0;
                        bad_left_next  = 4'd0;
                        next_state     = LOSS_DELAY;

                    end
                    else begin

                        bad_bytes_next = bad_bytes + 6'd1;

                        if (bad_left == 4'd1) begin
                            bad_left_next = 4'd0;
                            next_state    = SYNC_LSB;
                        end
                        else begin
                            bad_left_next = bad_left - 4'd1;
                        end
                    end
                end
            end


            //--------------------------------------------------
            // Delayed synchronization loss.
            //
            // frame_detect is lowered here, one cycle after the
            // 48th bad byte. The current rx_data is immediately
            // used as the first byte of a new unsynchronized
            // search, so no input byte is discarded.
            //--------------------------------------------------
            LOSS_DELAY: begin

                frame_detect_next       = 1'b0;
                fr_byte_position_next   = 4'd0;

                payload_left_next       = 4'd0;
                bad_left_next           = 4'd0;
                good_frames_next        = 2'd0;
                bad_bytes_next          = 6'd0;
                good_pending_next       = 1'b0;

                if (rx_data == HEADER1_LSB) begin
                    expected_msb_next = HEADER1_MSB;
                    next_state        = CHECK_MSB;
                end
                else if (rx_data == HEADER2_LSB) begin
                    expected_msb_next = HEADER2_MSB;
                    next_state        = CHECK_MSB;
                end
                else begin
                    next_state = SEARCH_LSB;
                end
            end


            //--------------------------------------------------
            // Defensive recovery
            //--------------------------------------------------
            default: begin

                next_state            = SEARCH_LSB;

                fr_byte_position_next = 4'd0;
                frame_detect_next     = 1'b0;

                expected_msb_next     = 8'h00;
                payload_left_next     = 4'd0;
                bad_left_next         = 4'd0;
                good_frames_next      = 2'd0;
                bad_bytes_next        = 6'd0;
                good_pending_next     = 1'b0;
            end

        endcase
    end


    //----------------------------------------------------------
    // Sequential registers
    //----------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            state            <= SEARCH_LSB;

            fr_byte_position <= 4'd0;
            frame_detect     <= 1'b0;

            expected_msb     <= 8'h00;
            payload_left     <= 4'd0;
            bad_left         <= 4'd0;

            good_frames      <= 2'd0;
            bad_bytes        <= 6'd0;

            good_pending     <= 1'b0;

        end
        else begin

            state            <= next_state;

            fr_byte_position <= fr_byte_position_next;
            frame_detect     <= frame_detect_next;

            expected_msb     <= expected_msb_next;
            payload_left     <= payload_left_next;
            bad_left         <= bad_left_next;

            good_frames      <= good_frames_next;
            bad_bytes        <= bad_bytes_next;

            good_pending     <= good_pending_next;
        end
    end

endmodule
