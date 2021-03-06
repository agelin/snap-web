{-# LANGUAGE OverloadedStrings #-}

module Views.ReplyForm where

import           Data.Text              (Text)
import qualified Data.Text              as T
import           Snap
import           Text.Digestive
import           Text.Digestive.FormExt
import           Text.Digestive.Snap

------------------------------------------------------------

data ReplyVo = ReplyVo
               { replyToTopicId :: T.Text
               , replyToReplyId :: T.Text  -- Maybe Empty
               , replyContent   :: T.Text
               } deriving (Show)

------------------------------------------------------------


runReplyForm :: MonadSnap m => m (View Text, Maybe ReplyVo)
runReplyForm = runForm "reply-to-topic-form" replyForm


replyForm :: Monad m => Form Text m ReplyVo
replyForm = ReplyVo
    <$> "replyToTopicId"  .: checkRequired "replyToTopicId is required" (text Nothing)
    <*> "replyToReplyId"  .: text Nothing
    <*> "content"         .: contentValidation (text Nothing)

------------------------------------------------------------

runReplyToRelpyForm :: MonadSnap m => m (View Text, Maybe ReplyVo)
runReplyToRelpyForm = runForm "reply-to-reply-form" replyToRelpyForm

-- |
--
replyToRelpyForm :: Monad m => Form Text m ReplyVo
replyToRelpyForm = ReplyVo
    <$> "replyToTopicId"  .: checkRequired "replyToReplyTopicId is required" (text Nothing)
    <*> "replyToReplyId"  .: checkRequired "replyToReplyReplyId is required" (text Nothing)
    <*> "replyContent"  .: replyOfReplyContentMaxLength (contentValidation (text Nothing))

replyOfReplyContentMaxLength :: Monad m => Form Text m Text -> Form Text m Text
replyOfReplyContentMaxLength = checkMaxLength 160


------------------------------------------------------------

contentValidation :: Monad m => Form Text m Text -> Form Text m Text
contentValidation = checkMinLength 6 . checkRequired "Reply content can not be empty."
