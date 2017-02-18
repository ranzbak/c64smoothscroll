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
  lda #23   
  sta $d018 // Text mode to lower
  
  sei
textrestart:
  lda #<text 
  sta TEXTADR
  lda #>text
  sta TEXTADR+1
 
loop:  
  inc $d012 // Inclease the raster line interrupt 
  bne loop // when 0 trigger, soo durty it hurts

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
  beq loop

  lda SCRLADR,Y
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
getnewchar:
  //TEXTADR  = *+1
  lda (TEXTADR,X) // Load the current character
  beq textrestart // When 0 end of string is reached.

  iny 
  bmi *+4
  ldx #$27

nobegin:  
  inc TEXTADR
  bne *+4
  inc TEXTADR+1

  tay  // Transfer A to Y
  bmi dirchange // A < than num

  sta SCRLADR,X 
  bpl loop // Jump to main loop
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
  bne loop
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
