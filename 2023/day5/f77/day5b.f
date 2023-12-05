      PROGRAM DAY5B
      IMPLICIT NONE
      REAL(4) STTIME, EDTIME
      CHARACTER*256 FNAME
      INTEGER(8) SEEDS(20)
      INTEGER(8) MAPS(3,50,7)
      INTEGER NUMMAP(7)
      INTEGER I, NSEEDS, NRANGS
      INTEGER(8) J
      INTEGER(8) RANGES(2,160)
      STTIME = SECNDS(0.0)
      IF (IARGC() .NE. 1) THEN
         WRITE (0,*) 'usage: day5a <input.txt>'
         STOP 1
      ENDIF
      CALL GETARG(1,FNAME)

      CALL RDATA(FNAME,SEEDS,NSEEDS,MAPS,NUMMAP)

      DO 20 I=1,NSEEDS/2
         RANGES(1,I) = SEEDS(2*I-1)
         RANGES(2,I) = SEEDS(2*I-1) + SEEDS(2*I) - 1
 20   CONTINUE
      NRANGS = NSEEDS/2
      DO 30 I=1,7
         CALL TRARAN(RANGES,NRANGS,MAPS(:,:,I),NUMMAP(I))
 30   CONTINUE

      J = RANGES(1,1)
      DO 40 I=2,NRANGS
         J = MIN(J,RANGES(1,I))
 40   CONTINUE
      WRITE(*,*) J

      EDTIME = SECNDS(0.0)
 10   FORMAT ('Elapsed time ',F12.9,' seconds')
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

      SUBROUTINE TRARAN(RANGES,NRANGS,MAP,N)
      IMPLICIT NONE
      INTEGER(8) RANGES(2,160)
      INTEGER(8) MAP(3,50)
      INTEGER NRANGS, N, I, J, NNRANGS
      INTEGER(8) LB, UB
      INTEGER(8) NRANG(2,160)      
      LOGICAL FOUND
      DO 10 I=1,N
         NNRANGS = 0
         LB = MAP(2,I)
         UB = MAP(3,I)
         DO 20 J = 1,NRANGS
            IF (RANGES(1,J) .LT. LB .AND. LB .LE. RANGES(2,J) .AND.
     *          RANGES(2,J) .LE. UB) THEN
               NNRANGS = NNRANGS + 1
               NRANG(1,NNRANGS) = RANGES(1,J)
               NRANG(2,NNRANGS) = LB-1
               NNRANGS = NNRANGS + 1
               NRANG(1,NNRANGS) = LB
               NRANG(2,NNRANGS) = RANGES(2,J)
            ELSE IF (LB .LE. RANGES(1,J) .AND. RANGES(1,J) .LE. UB .AND.
     *               UB .LT. RANGES(2,J)) THEN
               NNRANGS = NNRANGS + 1
               NRANG(1,NNRANGS) = RANGES(1,J)
               NRANG(2,NNRANGS) = UB
               NNRANGS = NNRANGS + 1
               NRANG(1,NNRANGS) = UB+1
               NRANG(2,NNRANGS) = RANGES(2,J)
            ELSE IF (RANGES(1,J).LT.LB.AND.UB.LT.RANGES(2,J)) THEN
               NNRANGS = NNRANGS + 1
               NRANG(1,NNRANGS) = RANGES(1,J)
               NRANG(2,NNRANGS) = LB-1
               NNRANGS = NNRANGS + 1
               NRANG(1,NNRANGS) = LB
               NRANG(2,NNRANGS) = UB
               NNRANGS = NNRANGS + 1
               NRANG(1,NNRANGS) = UB+1
               NRANG(2,NNRANGS) = RANGES(2,J)
            ELSE IF (RANGES(1,J).GT.UB.OR.RANGES(2,J).LT.LB.OR.
     *              LB.LE.RANGES(1,J).AND.RANGES(2,J).LE.UB) THEN
               NNRANGS = NNRANGS + 1
               NRANG(1,NNRANGS) = RANGES(1,J)
               NRANG(2,NNRANGS) = RANGES(2,J)               
            ELSE
               STOP 1
            ENDIF
 20      CONTINUE
         RANGES = NRANG
         NRANGS = NNRANGS
 10   CONTINUE
      NNRANGS = 0
      DO 30 J=1,NRANGS
         FOUND = .FALSE.
         DO 40 I=1,N
            LB = MAP(2,I)
            UB = MAP(3,I)            
            IF (LB.LE.RANGES(1,J).AND.RANGES(2,J).LE.UB) THEN
               NNRANGS = NNRANGS + 1
               NRANG(1,NNRANGS) = MAP(1,I) + (RANGES(1,J)-MAP(2,I))
               NRANG(2,NNRANGS) = MAP(1,I) + (RANGES(2,J)-MAP(2,I))
               FOUND = .TRUE.
            ENDIF
 40      CONTINUE
         IF (.NOT.FOUND) THEN
               NNRANGS = NNRANGS + 1
               NRANG(1,NNRANGS) = RANGES(1,J)
               NRANG(2,NNRANGS) = RANGES(2,J)
         ENDIF
 30   CONTINUE
      NRANGS = NNRANGS
      RANGES = NRANG
      END SUBROUTINE
