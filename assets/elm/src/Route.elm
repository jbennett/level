module Route exposing (Route(..), fromUrl, href, parser, pushUrl, replaceUrl, toLogin, toSpace)

{-| Routing logic for the application.
-}

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Route.Group
import Route.Groups
import Route.Inbox
import Route.Posts
import Route.SpaceUsers
import Url exposing (Url)
import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, top)



-- ROUTING --


type Route
    = Spaces
    | NewSpace
    | Root String
    | SetupCreateGroups String
    | SetupInviteUsers String
    | Posts Route.Posts.Params
    | Inbox Route.Inbox.Params
    | SpaceUsers Route.SpaceUsers.Params
    | Groups Route.Groups.Params
    | Group Route.Group.Params
    | NewGroup String
    | Post String String
    | UserSettings
    | SpaceSettings String


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Spaces (s "spaces")
        , Parser.map NewSpace (s "spaces" </> s "new")
        , Parser.map Root Parser.string
        , Parser.map SetupCreateGroups (Parser.string </> s "setup" </> s "groups")
        , Parser.map SetupInviteUsers (Parser.string </> s "setup" </> s "invites")
        , Parser.map Posts Route.Posts.parser
        , Parser.map Inbox Route.Inbox.parser
        , Parser.map SpaceUsers Route.SpaceUsers.parser
        , Parser.map Groups Route.Groups.parser
        , Parser.map NewGroup (Parser.string </> s "groups" </> s "new")
        , Parser.map Group Route.Group.parser
        , Parser.map Post (Parser.string </> s "posts" </> Parser.string)
        , Parser.map UserSettings (s "user" </> s "settings")
        , Parser.map SpaceSettings (Parser.string </> s "settings")
        ]



-- PUBLIC HELPERS


href : Route -> Attribute msg
href route =
    Attr.href (toString route)


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    Nav.pushUrl key (toString route)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (toString route)


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


toLogin : Cmd msg
toLogin =
    Nav.load "/login"


toSpace : String -> Cmd msg
toSpace slug =
    Nav.load ("/" ++ slug ++ "/")



-- INTERNAL --


toString : Route -> String
toString page =
    case page of
        Spaces ->
            absolute [ "spaces" ] []

        NewSpace ->
            absolute [ "spaces", "new" ] []

        Root slug ->
            absolute [ slug ] []

        SetupCreateGroups slug ->
            absolute [ slug, "setup", "groups" ] []

        SetupInviteUsers slug ->
            absolute [ slug, "setup", "invites" ] []

        Posts params ->
            Route.Posts.toString params

        Inbox params ->
            Route.Inbox.toString params

        SpaceUsers params ->
            Route.SpaceUsers.toString params

        Groups params ->
            Route.Groups.toString params

        Group params ->
            Route.Group.toString params

        NewGroup slug ->
            absolute [ slug, "groups", "new" ] []

        Post slug id ->
            absolute [ slug, "posts", id ] []

        UserSettings ->
            absolute [ "user", "settings" ] []

        SpaceSettings slug ->
            absolute [ slug, "settings" ] []
