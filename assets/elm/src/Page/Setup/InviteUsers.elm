module Page.Setup.InviteUsers exposing (ExternalMsg(..), Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Event exposing (Event)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.CompleteSetupStep as CompleteSetupStep
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import View.Layout exposing (spaceLayout)



-- MODEL


type alias Model =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , isSubmitting : Bool
    }



-- PAGE PROPERTIES


title : String
title =
    "Invite your colleagues"



-- LIFECYCLE


init : String -> Session -> Task Session.Error ( Session, Model )
init spaceSlug session =
    session
        |> SetupInit.request spaceSlug
        |> Task.andThen buildModel


buildModel : ( Session, SetupInit.Response ) -> Task Session.Error ( Session, Model )
buildModel ( session, { viewer, space, bookmarks } ) =
    let
        model =
            Model
                viewer
                space
                bookmarks
                False
    in
    Task.succeed ( session, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = Submit
    | Advanced (Result Session.Error ( Session, CompleteSetupStep.Response ))


type ExternalMsg
    = SetupStateChanged Space.SetupState
    | NoOp


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session, ExternalMsg )
update msg session model =
    case msg of
        Submit ->
            let
                cmd =
                    CompleteSetupStep.request (Space.getId model.space) Space.InviteUsers False session
                        |> Task.attempt Advanced
            in
            ( ( { model | isSubmitting = True }, cmd ), session, NoOp )

        Advanced (Ok ( newSession, CompleteSetupStep.Success nextState )) ->
            -- TODO: Re-instate navigation to next state
            ( ( model, Cmd.none ), newSession, SetupStateChanged nextState )

        Advanced (Err Session.Expired) ->
            redirectToLogin session model

        Advanced (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), session, NoOp )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session, ExternalMsg )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session, NoOp )



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarks = insertUniqueBy Group.getId group model.bookmarks }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarks = removeBy Group.getId group model.bookmarks }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute { viewer, space, bookmarks, isSubmitting } =
    let
        spaceData =
            Repo.getSpace repo space
    in
    spaceLayout repo
        viewer
        space
        bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto py-24 max-w-400px leading-normal" ]
                [ h2 [ class "mb-6 font-extrabold text-3xl" ] [ text "Invite your colleagues" ]
                , body spaceData.openInvitationUrl
                , button [ class "btn btn-blue", onClick Submit, disabled isSubmitting ] [ text "Next step" ]
                ]
            ]
        ]


body : Maybe String -> Html Msg
body maybeUrl =
    case maybeUrl of
        Just url ->
            div []
                [ p [ class "mb-6" ] [ text "The best way to try out Level is with other people! Anyone with this link can join the space:" ]
                , input [ class "mb-6 input-field font-mono text-sm", value url ] []
                ]

        Nothing ->
            p [ class "mb-6" ] [ text "Open invitations are disabled." ]
