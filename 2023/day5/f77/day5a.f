      PROGRAM DAY5A
      IMPLICIT NONE
      REAL(4) STTIME, EDTIME
      CHARACTER*256 FNAME
      INTEGER(8) SEEDS(20)
      INTEGER(8) MAPS(3,50,7)
      INTEGER NUMMAP(7)
      INTEGER I, J, NSEEDS
      INTEGER(8) TRANS
      STTIME = SECNDS(0.0)
      IF (IARGC() .NE. 1) THEN
         WRITE (0,*) 'usage: day5a <input.txt>'
         STOP 1
      ENDIF
      CALL GETARG(1,FNAME)

      CALL RDATA(FNAME,SEEDS,NSEEDS,MAPS,NUMMAP)

      DO 20 I=1,7
         DO 30 J = 1,NSEEDS
            SEEDS(J) = TRANS(SEEDS(J),MAPS(:,:,I),NUMMAP(I))
 30      CONTINUE 
 20   CONTINUE

      DO 40 I=2,NSEEDS
         SEEDS(1) = MIN(SEEDS(1),SEEDS(I))
 40   CONTINUE
      WRITE (*,*) SEEDS(1)

      EDTIME = SECNDS(0.0)
 10   FORMAT ('Elapsed time ',F9.6,' seconds')
      WRITE (*,10) (EDTIME-STTIME)
      END PROGRAM

      SUBROUTINE RDATA(FNAME,SEEDS,NSEEDS,MAPS,NUMMAP)
      IMPLICIT NONE
      CHARACTER*256 FNAME
      INTEGER(8) SEEDS(20)
      INTEGER(8) MAPS(3,50,7)
      INTEGER NUMMAP(7)
      INTEGER NSEEDS
      INTEGER I, J, L, TRIMLEN
      CHARACTER*256 LINE
      OPEN(1, FILE=FNAME)
 10   FORMAT (A)
      READ(1,10) LINE
      L = TRIMLEN(LINE,LEN(LINE))
      I = INDEX(LINE,' ') + 1
      J = 1
 30   IF (I .LT. L) THEN
         READ (LINE(I:L),*) SEEDS(J)
         J = J+1
         I = I + INDEX(LINE(I+1:),' ') + 1
         GOTO 30
      ENDIF
      NSEEDS = J-1
      READ(1,10) LINE
      DO 40 I=1,7
         READ(1,10) LINE
 50      READ(1,10,END=60) LINE
         IF (TRIMLEN(LINE,LEN(LINE)) .EQ. 0) GOTO 40
         NUMMAP(I) = NUMMAP(I) + 1
         READ(LINE,*) MAPS(:,NUMMAP(I),I)
         GOTO 50
 40   CONTINUE
 60   CLOSE(1)
      MAPS(3,:,:) = MAPS(2,:,:) + MAPS(3,:,:) - 1
      END SUBROUTINE

      FUNCTION TRIMLEN(LINE, N)
      IMPLICIT NONE
      CHARACTER(*) LINE
      INTEGER TRIMLEN, N
      DO 10 TRIMLEN=N,1,-1
         IF (LINE(TRIMLEN:TRIMLEN).NE.' ') RETURN
 10   CONTINUE
      END FUNCTION

      FUNCTION TRANS(S,MAP,N)
      IMPLICIT NONE
      INTEGER(8) TRANS, S
      INTEGER I, N
      INTEGER(8) MAP(3,50)
      DO 10 I = 1,N
         IF (S.GE.MAP(2,I) .AND. S.LE.MAP(3,I)) THEN
            TRANS = MAP(1,I) + (S-MAP(2,I))
            RETURN
         ENDIF
 10   CONTINUE
      TRANS = S
      END FUNCTION
