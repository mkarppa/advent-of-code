      PROGRAM DAY11
      IMPLICIT NONE
      INTEGER(1) M(140,140)
      INTEGER(2) G(2,439)
      INTEGER I, J, K, NROWS, NCOLS, NGAL
      INTEGER(4) EX
      CHARACTER*256 FNAME
      CHARACTER*256 EXARG
      REAL STTIME, EDTIME

      STTIME = SECNDS(0.0)

      IF (IARGC() .NE. 2) THEN
         WRITE (0,*) 'usage: day11 <input.txt> <num>'
         STOP 1
      ENDIF

      CALL GETARG(1,FNAME)
      CALL GETARG(2,EXARG)

      READ(EXARG,*) EX
      CALL RDATA(FNAME, M, G, NROWS, NCOLS, NGAL)

      CALL SOLVE(M,G,NROWS,NCOLS,NGAL,EX)

      EDTIME = SECNDS(0.0)
 10   FORMAT ('Elapsed time ',F9.6,' seconds')
      WRITE (*,10) (EDTIME-STTIME)

      END


      SUBROUTINE RDATA(FNAME, M, G, NROWS, NCOLS, NGAL)
      IMPLICIT NONE
      CHARACTER*256 FNAME
      INTEGER(1) M(140,140)
      INTEGER(2) G(2,439)
      INTEGER NROWS, NCOLS, NGAL, I, J, K
      CHARACTER*256 LINE
      OPEN(1,FILE=FNAME)
 10   FORMAT (A)
      I = 0
      J = 0
      K = 0
      DO 30
         READ(1,10,END=20) LINE
         I = I + 1
         J = 0
         DO 40
            J = J + 1
            IF (LINE(J:J) .EQ. ' ') THEN
               GOTO 30
            ELSEIF (LINE(J:J) .EQ. '#') THEN
               K = K + 1
               M(J,I) = 1
               G(1,K) = I
               G(2,K) = J
            ELSE
               M(J,I) = 0
            ENDIF
 40      CONTINUE
 30   CONTINUE
 20   CLOSE(1)
      NROWS = I
      NCOLS = J-1
      NGAL = K
      END

      SUBROUTINE SOLVE(M,G,NROWS,NCOLS,NGAL,EX)
      IMPLICIT NONE
      INTEGER(1) M(140,140)
      INTEGER(2) G(2,*)
      INTEGER NROWS, NCOLS, NGAL, I, J, K, X1, X2, Y1, Y2
      INTEGER(4) EX
      INTEGER(4) CL(140)
      INTEGER(4) RL(140)
      INTEGER(8) CTOE(140)
      INTEGER(8) RTOE(140)
      INTEGER(8) S
      DO 10 I = 1,NROWS
         DO 20 J = 1,NCOLS
            IF (M(J,I) .EQ. 1) THEN
               RL(I) = 1
               GOTO 10
            ENDIF
 20      CONTINUE
         RL(I) = EX
 10   CONTINUE

      DO 30 J = 1,NCOLS
         DO 40 I = 1,NROWS
            IF (M(J,I) .EQ. 1) THEN
               CL(J) = 1
               GOTO 30
            ENDIF
 40      CONTINUE
         CL(J) = EX
 30   CONTINUE

      RTOE(1) = 1
      DO 50 I=2,NROWS
         RTOE(I) = RTOE(I-1) + RL(I-1)         
 50   CONTINUE

      CTOE(1) = 1
      DO 60 J=2,NCOLS
         CTOE(J) = CTOE(J-1) + CL(J-1)         
 60   CONTINUE

      S = 0
      DO 70 I=1,NGAL-1
         Y1 = RTOE(G(1,I))
         X1 = CTOE(G(2,I))
         DO 80 J=I+1,NGAL
            Y2 = RTOE(G(1,J))
            X2 = CTOE(G(2,J))
            S = S + ABS(X2-X1) + ABS(Y2-Y1)
 80      CONTINUE
 70   CONTINUE

      WRITE (*,*) S

      END
