{-# LANGUAGE OverloadedStrings, ExtendedDefaultRules #-}

module Views.TopicSplices
       ( topicSplices 
       , topicDetailSplices ) where

import           Control.Arrow (second)
import           Control.Monad.Trans
import           Control.Monad
import           Data.Maybe (isJust)
import           Text.Templating.Heist
import qualified Data.Text as T

import Application
import Models.Exception
import Models.Topic
import Models.Reply
import Models.User
import Views.MarkdownSplices
import Views.ReplySplices
import Views.UserSplices
import Views.PaginationSplices
import Views.Types
import Views.Utils
import Models.Utils


------------------------------------------------------------------------------

instance SpliceRenderable Topic where
   toSplice = renderTopic

------------------------------------------------------------------------------
                    
-- | display all topics.
-- 

-- FIXME: what if no topics at all??
-- 
topicSplices :: Integral a 
                => Maybe a 
                -> [(T.Text, Splice AppHandler)]
topicSplices page = [ ("homeTopics", allTopicsSplice page) ]

allTopicsSplice :: Integral a
                   => Maybe a
                   -> Splice AppHandler
allTopicsSplice page = do
    t <- lift (fmap (filter (isJust . _topicId)) findAllTopic)
    (xs, splice) <- lift $ paginationHandler 2 currentPage' t
    runChildrenWith
      [ ("allTopics", mapSplices renderTopicSimple xs)
      , ("pagination", splice)]
    where total' = fromIntegral . length
          currentPage' :: Integral a => a
          currentPage' = maybe 1 fromIntegral page
          

------------------------------------------------------------------------------

-- | Splices used at Topic Detail page. 
--   Display either a topic or error msg.    
-- 
topicDetailSplices :: Either UserException Topic -> [(T.Text, Splice AppHandler)]
topicDetailSplices = eitherToSplices


------------------------------------------------------------------------------

-- | Single Topic to Splice
-- 
renderTopicSimple :: Topic -> Splice AppHandler
renderTopicSimple tag = do
    usr <- findTopicAuthor tag
    runChildrenWithText (topicToSpliceContent tag usr)

-- | Render a Topic with its replies.
-- 
renderTopic :: Topic -> Splice AppHandler
renderTopic tag = do
    rs <- lift $ findReplyPerTopic (textToObjectId $ getTopicId tag)
    user <- findTopicAuthor tag
    runChildrenWith $
      map (second textSplice) (topicToSpliceContent tag user)
      ++ [ ("topicContent", markdownToHtmlSplice $ _content tag)
         , ("replyPerTopic", allReplyPerTopicSplice rs)
         , ("topicEditable", hasEditPermissionSplice user) ]

------------------------------------------------------------------------------
    
-- | @Splice@ is type synonium as @Splice m = HeistT m Template@
-- 
findTopicAuthor :: Topic -> HeistT AppHandler User
findTopicAuthor topic = lift (findUser' topic)
                        where findUser' = findOneUser . _author

-- findTopicAuthorName :: Topic -> HeistT AppHandler T.Text
-- findTopicAuthorName topic = liftM _userDisplayName (findTopicAuthor topic)


-- | Topic to Splice "VO"
-- 
topicToSpliceContent :: Topic -> User -> [(T.Text, T.Text)]
topicToSpliceContent topic user = [ ("topicTitle", _title topic)
                              , ("topicAuthor", _userDisplayName user)
                              , ("topicAuthorId", sToText $ _author topic)
                              , ("topicCreateAt", formatUTCTime $ _createAt topic)
                              , ("topicUpdateAt", formatUTCTime $ _updateAt topic)
                              , ("topicId", getTopicId topic) ]
