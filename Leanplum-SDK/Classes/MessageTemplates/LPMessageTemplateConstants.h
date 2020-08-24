//
//  LPMessageTemplateConstants.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 1/27/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LPMT_ALERT_NAME @"Alert"
#define LPMT_CONFIRM_NAME @"Confirm"
#define LPMT_PUSH_ASK_TO_ASK @"Push Ask to Ask"
#define LPMT_REGISTER_FOR_PUSH @"Register For Push"
#define LPMT_CENTER_POPUP_NAME @"Center Popup"
#define LPMT_INTERSTITIAL_NAME @"Interstitial"
#define LPMT_WEB_INTERSTITIAL_NAME @"Web Interstitial"
#define LPMT_OPEN_URL_NAME @"Open URL"
#define LPMT_HTML_NAME @"HTML"
#define LPMT_APP_RATING_NAME @"Request App Rating"
#define LPMT_ICON_CHANGE_NAME @"Change App Icon"

#define LPMT_ARG_TITLE @"Title"
#define LPMT_ARG_MESSAGE @"Message"
#define LPMT_ARG_URL @"URL"
#define LPMT_ARG_URL_CLOSE @"Close URL"
#define LPMT_ARG_URL_OPEN @"Open URL"
#define LPMT_ARG_URL_TRACK @"Track URL"
#define LPMT_ARG_URL_ACTION @"Action URL"
#define LPMT_ARG_URL_TRACK_ACTION @"Track Action URL"
#define LPMT_ARG_DISMISS_ACTION @"Dismiss action"
#define LPMT_ARG_ACCEPT_ACTION @"Accept action"
#define LPMT_ARG_CANCEL_ACTION @"Cancel action"
#define LPMT_ARG_CANCEL_TEXT @"Cancel text"
#define LPMT_ARG_ACCEPT_TEXT @"Accept text"
#define LPMT_ARG_DISMISS_TEXT @"Dismiss text"
#define LPMT_HAS_DISMISS_BUTTON @"Has dismiss button"
#define LPMT_ARG_HTML_TEMPLATE @"__file__Template"

#define LPMT_ARG_TITLE_TEXT @"Title.Text"
#define LPMT_ARG_TITLE_COLOR @"Title.Color"
#define LPMT_ARG_MESSAGE_TEXT @"Message.Text"
#define LPMT_ARG_MESSAGE_COLOR @"Message.Color"
#define LPMT_ARG_ACCEPT_BUTTON_TEXT @"Accept button.Text"
#define LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR @"Accept button.Background color"
#define LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR @"Accept button.Text color"
#define LPMT_ARG_CANCEL_BUTTON_TEXT @"Cancel button.Text"
#define LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR @"Cancel button.Background color"
#define LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR @"Cancel button.Text color"
#define LPMT_ARG_BACKGROUND_IMAGE @"Background image"
#define LPMT_ARG_BACKGROUND_COLOR @"Background color"
#define LPMT_ARG_LAYOUT_WIDTH @"Layout.Width"
#define LPMT_ARG_LAYOUT_HEIGHT @"Layout.Height"
#define LPMT_ARG_HTML_HEIGHT @"HTML Height"
#define LPMT_ARG_HTML_WIDTH @"HTML Width"
#define LPMT_ARG_HTML_ALIGN @"HTML Align"
#define LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE @"Tap Outside to Close"
#define LPMT_ARG_HTML_ALIGN_TOP @"Top"
#define LPMT_ARG_HTML_ALIGN_BOTTOM @"Bottom"
#define LPMT_ARG_APP_ICON @"__iOSAppIcon"

#define LPMT_DEFAULT_ALERT_MESSAGE @"Alert message goes here."
#define LPMT_DEFAULT_CONFIRM_MESSAGE @"Confirmation message goes here."
#define LPMT_DEFAULT_ASK_TO_ASK_MESSAGE @"Tap OK to receive important notifications from our app."
#define LPMT_DEFAULT_POPUP_MESSAGE @"Popup message goes here."
#define LPMT_DEFAULT_INTERSTITIAL_MESSAGE @"Interstitial message goes here."
#define LPMT_DEFAULT_OK_BUTTON_TEXT @"OK"
#define LPMT_DEFAULT_YES_BUTTON_TEXT @"Yes"
#define LPMT_DEFAULT_NO_BUTTON_TEXT @"No"
#define LPMT_DEFAULT_LATER_BUTTON_TEXT @"Maybe Later"
#define LPMT_DEFAULT_URL @"http://www.example.com"
#define LPMT_DEFAULT_CLOSE_URL @"http://leanplum/close"
#define LPMT_DEFAULT_OPEN_URL @"http://leanplum/loadFinished"
#define LPMT_DEFAULT_TRACK_URL @"http://leanplum/track"
#define LPMT_DEFAULT_ACTION_URL @"http://leanplum/runAction"
#define LPMT_DEFAULT_TRACK_ACTION_URL @"http://leanplum/runTrackedAction"
#define LPMT_DEFAULT_HAS_DISMISS_BUTTON YES
#define LPMT_DEFAULT_APP_ICON @"__iOSAppIcon-PrimaryIcon.png"

#define LPMT_ICON_FILE_PREFIX @"__iOSAppIcon-"
#define LPMT_ICON_PRIMARY_NAME @"PrimaryIcon"

#define LPMT_APP_STORE_SCHEMA @"itms-apps"

#define LPMT_DEFAULT_CENTER_POPUP_WIDTH 300
#define LPMT_DEFAULT_CENTER_POPUP_HEIGHT 250

#define LIGHT_GRAY (246.0/255.0)

#define LOG_LP_MESSAGE_EXCEPTION LPLog(LPError, @"Error in message template %@: %@\n%@", \
context.actionName, exception, [exception callStackSymbols])
