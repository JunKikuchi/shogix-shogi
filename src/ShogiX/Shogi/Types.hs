module ShogiX.Shogi.Types where

import           RIO
import           ShogiX.Clocks.Types            ( Clocks )

-- | 将棋作成
--
-- >>> import RIO
-- >>> import qualified RIO.Map as Map
-- >>> import qualified RIO.NonEmpty as NonEmpty
-- >>> import qualified ShogiX.Clocks as Clocks
-- >>>
-- >>> let board = Board Map.empty
-- >>> let stands = Stands [] []
-- >>> let position = Position Black board stands Clocks.infinity
-- >>> let shogi = fmap (Shogi Open . Positions) (NonEmpty.nonEmpty [position])
-- >>>
-- >>> shogi
-- Just (Shogi {shogiStauts = Open, shogiPositions = Positions {unPositions = Position {positionTurn = Black, positionBoard = Board {unBoard = fromList []}, positionStands = Stands {blackStand = [], whiteStand = []}, positionClocks = Clocks {blackClock = Infinity, whiteClock = Infinity}} :| []}})

-- | 先手|後手
data Color
  = Black -- ^ 先手
  | White -- ^ 後手
  deriving Show

-- | 将棋
data Shogi
  = Shogi
  { shogiStauts    :: Status    -- ^ 対局状態
  , shogiPositions :: Positions -- ^ 局面
  } deriving Show

-- | 対局状態
data Status
  = Open                      -- ^ 対局中
  | Draw DrawStatus           -- ^ 引き分け
  | Closed Winner CloseStatus -- ^ 対局終了
  deriving Show

-- | 引き分けの状態
data DrawStatus
  = Repetition  -- ^ 千日手
  | ImpasseDraw -- ^ 持将棋
  deriving Show

-- | 勝者
type Winner = Color

-- | 対局終了の状態
data CloseStatus
  = Mate                  -- ^ 詰み
  | Illegal IllegalStatus -- ^ 反則
  | Resign                -- ^ 投了
  | Timeout               -- ^ 時間切れ
  | ImpasseClose          -- ^ 持将棋
  deriving Show

-- | 反則で対局終了の状態
data IllegalStatus
  = IllegalMove           -- ^ 駒移動違反
  | DoublePawns           -- ^ 二歩
  | DroppedPawnMate       -- ^ 打ち歩詰め
  | RepetitionRepetedMate -- ^ 連続王手の千日手
  | AbandonCheck          -- ^ 王手放置
  deriving Show

-- | 局面ログ
newtype Positions = Positions { unPositions :: NonEmpty Position } deriving Show

-- | 局面
data Position
  = Position
  { positionTurn   :: Turn   -- ^ 手番
  , positionBoard  :: Board  -- ^ 将棋盤
  , positionStands :: Stands -- ^ 駒台
  , positionClocks :: Clocks  -- ^ 時計
  } deriving Show

-- | 手番
type Turn = Color

-- | 将棋盤
newtype Board = Board { unBoard :: Map Square Piece } deriving Show

-- | 将棋盤のマス目
type Square = (File, Rank)

-- | 将棋盤の筋
data File = F9 | F8 | F7 | F6 | F5 | F4 | F3 | F2 | F1 deriving (Show, Eq, Ord)

-- | 将棋盤の段
data Rank = R1 | R2 | R3 | R4 | R5 | R6 | R7 | R8 | R9 deriving (Show, Eq, Ord)

-- | 駒台
data Stands
  = Stands
  { blackStand :: [PieceType] -- ^ 先手の駒台
  , whiteStand :: [PieceType] -- ^ 後手の駒台
  } deriving Show

-- | 駒
data Piece = Piece Color PieceType deriving Show

-- | 駒の種類
data PieceType
  = Pawn           -- ^ 歩兵
  | Lance          -- ^ 香車
  | Knight         -- ^ 桂馬
  | Silver         -- ^ 銀将
  | PromotedSilver -- ^ 成銀
  | Gold           -- ^ 金将
  | PromotedLance  -- ^ 成香
  | PromotedKnight -- ^ 成桂
  | PromotedPawn   -- ^ と金
  | Bishop         -- ^ 角行
  | PromotedBishop -- ^ 龍馬
  | Rook           -- ^ 飛車
  | PromotedRook   -- ^ 龍王
  | King           -- ^ 玉将
  deriving Show

-- | 駒の移動
data Move
  = Move DestSquare SrcSquare Promotion -- ^駒移動
  | Drop DestSquare PieceType           -- ^駒打ち
  | CloseResign                         -- ^投了
  | CloseTimeout                        -- ^時間切れ
  | CloseImpasse                        -- ^持将棋
  deriving Show

-- | 移動元のマス目
type DestSquare = Square

-- | 移動先のマス目
type SrcSquare = Square

-- | 駒の成り指定
type Promotion = Bool

-- | 駒の移動先
newtype Movables = Movables { unMovables :: Map SrcSquare (Set (DestSquare, Promotable)) } deriving Show

-- | 駒成り可能状態
data Promotable
  = No     -- ^ 不成のみ
  | Option -- ^ 成り,不成を選択可能
  | Must   -- ^ 成りのみ
  deriving (Show, Eq, Ord)
