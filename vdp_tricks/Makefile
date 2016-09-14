CAT=cat
ECHO=echo
EMULATOR=openmsx
MAINFILE=vdp_tricks.asm
OUTFILE=vdptrcks
PASMO=pasmo
RM=rm -f
MACHINE=-machine C-BIOS_MSX2

.PHONY: clean default rom superclean test

default:
	make rom

rom:
	${PASMO} -d -v -1 --err \
        ${MAINFILE} ${OUTFILE}.rom |\
        tee ${OUTFILE}.log 2> ${OUTFILE}.err

test:
	${EMULATOR} ${MACHINE} ${OUTFILE}.rom

clean:
	${RM} -f ${OUTFILE}.rom 2>/dev/null

superclean:
	${RM} -f ${OUTFILE}.err ${OUTFILE}.log ${OUTFILE}.rom 2>/dev/null

