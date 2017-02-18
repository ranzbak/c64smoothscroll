BasicUpstart2(begin)      // <- This creates a basic sys line that can start your program
* = $1000 "Main Program"    // <- The name 'Main program' will appear in the memory map when assembling   jsr clear

// Zero page address
.var Q = 2
.var XPIXSHIFT = 4
.var TMP1 = 5
.var TEXTADR = 6

// Vic memory 
.var SCRLADR = $0400
 
begin:
  jsr $E544 // Clear screen
  
  sei // Disable interrupts

  lda #23   
  sta $d018 // Text mode to lower

  lda #%01111111 // Switch off interrupts from the CIA-1
  sta $dc0d
  and $d011      // Clear most significant bit in VIC raster register
  sta $d011
  lda #210       // Set raster line to interrupt on
  sta $d012
  lda #<irq      // Set the interrupt vector to point to the service routine
  sta $0314
  lda #>irq
  sta $0315
  lda #%00000001 // Enable raster interrupt to VIC
  sta $d01a
  
  asl $d019  // Ack any previous raster interrupt
  bit $dc0d  // reading the interrupt control registers 
  bit $dd0d  // clears them

  cli

  // Set the pointer te the start of the text block
  lda #<text 
  sta TEXTADR
  lda #>text
  sta TEXTADR+1
 
// Main loop
loop:  
  jmp loop // Endless loop doing nothing

// Interrupt handler
irq:
  lda #7      // Turn screen frame yellow
  sta $d020

.var DESTSTART=*+1 
  ldx #39 //39
.var SRCSTART=*+1       
  ldy #39 //37

xpixshiftadd:
  dec XPIXSHIFT

  lda XPIXSHIFT // shift register
  and #7
  sta $d016

  cmp XPIXSHIFT 
  sta XPIXSHIFT
  beq endirq

  lda SCRLADR,Y   // Getting the characters from the string on screen.
  sta TMP1
  lda SCRLADR-1,Y
  pha             // Push acc
s:
  lda TMP1
  sta SCRLADR-1,X
  pla             // Pull acc
  sta TMP1
  lda SCRLADR-2,Y
  pha             // push acc
  dey
  dex
  bne s
  pla             // pull acc

// getnewchar:
  lda (TEXTADR,X) // Load the current character
  bne overrestart // If it's zero, start over
  lda #<text  // Reset to the beginning of the text
  sta TEXTADR
  lda #>text
  sta TEXTADR+1
  jmp endirq 
overrestart:

  iny 
  bmi nobegin
  ldx #$27

nobegin:  
  inc TEXTADR
  bne textlower
  inc TEXTADR+1

textlower:
  tay  // Transfer A to Y
  bmi dirchange // A < than num

  sta SCRLADR,X 
  bpl endirq // Jump to main loop
  //---------------------------------------
dirchange: 
  lda xpixshiftadd
  eor #$20
  sta xpixshiftadd

  ldx DESTSTART
  ldy SRCSTART
  dex
  iny
  stx SRCSTART
  sty DESTSTART
  //bne loop
endirq:
  lda #0
  sta $d020   // Background to black
  asl $d019   // Acknowledge interrupt 
  jmp $ea31   // Jump to kernal interrupt routine

//---------------------------------------
text:    
  .text " This scroller can"
  .text " scroll in forward"
  .text " and backward direc"
  .text "tion!               "
  .text "                    "
  .text "         "
  .byte $FF
  .text "won gnillorcs morf "
  .text "tfel ot thgiR ... . "
  .text "                    "
  .text "                    "
  .byte $FF,0
