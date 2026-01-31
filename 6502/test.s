PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e

counter = $020a ; 2 bytes

  .org $8000

reset:
  ldx #$ff
  txs
  cli  ; enable the interrupt

  ;-------------------
  ; 65C22
  ; enable inerrupt 
  lda #%10000010 
  sta IER 
  ; specify transition mode
  lda #$00 ; bit 0 must be '0' to specify negative edge trigger for CA1
  sta PCR

  ; configure input and output
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  lda #0
  sta counter
  sta counter + 1
  
loop:
  jmp loop

nmi:
irq:
  pha
  txa
  pha
  tya
  pha

  inc counter
  bne exit_irq
  inc counter + 1
  
exit_irq:    
  ldx #$ff  ; delay
  ldy #$ff
delay:
  dex
  bne delay
  dey
  bne delay

  bit PORTA  ; clears interrupt

  pla
  tay
  pla
  tax
  pla
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq