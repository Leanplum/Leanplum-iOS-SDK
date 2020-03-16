//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Leanplum/LPHtmlMessageTemplate.h>
#import <OCMock.h>

@interface LPHtmlMessageTemplate()

@property  (nonatomic, strong) UIView *popupGroup;
@property  (nonatomic, strong) WKWebView *popupView;
- (void)setupPopupView;
-(NSString *)htmlStringContentsOfFile:(NSString *)file;

@end

@interface LPActionContext(UnitTest)

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId;

@end

@interface LPHtmlMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPHtmlMessageSnapshotTest

- (void)setUp {
    [super setUp];
    //self.recordMode = YES;
}

- (void)tearDown {
    [super tearDown];
}

// commenting out until we can get this to run on CI
- (void)testView {
//     LPHtmlMessageTemplate *template = [[LPHtmlMessageTemplate alloc] init];
//     LPActionContext *context = [LPActionContext actionContextWithName:LPMT_HTML_NAME args:@{
//         LPMT_ARG_LAYOUT_WIDTH:@(LPMT_DEFAULT_CENTER_POPUP_WIDTH),
//         LPMT_ARG_LAYOUT_HEIGHT:@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT),
//         LPMT_ARG_URL_CLOSE: LPMT_DEFAULT_CLOSE_URL,
//         LPMT_ARG_URL_OPEN: LPMT_DEFAULT_OPEN_URL,
//         LPMT_ARG_URL_TRACK: LPMT_DEFAULT_TRACK_URL,
//         LPMT_ARG_URL_ACTION: LPMT_DEFAULT_ACTION_URL,
//         LPMT_ARG_URL_TRACK_ACTION: LPMT_DEFAULT_TRACK_ACTION_URL,
//         LPMT_ARG_HTML_ALIGN: LPMT_ARG_HTML_ALIGN_TOP,
//         LPMT_ARG_HTML_HEIGHT: @0,
//         LPMT_ARG_HTML_WIDTH: @"100%",
//         LPMT_ARG_HTML_Y_OFFSET: @"0px",
//         LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE: @NO,
//         LPMT_HAS_DISMISS_BUTTON: @NO,
// //        LPMT_ARG_HTML_TEMPLATE :nil
//     } messageId:@"666"];

//     id contextMock = OCMPartialMock(context);
//     OCMStub([contextMock numberNamed:LPMT_ARG_LAYOUT_WIDTH]).andReturn(@(LPMT_DEFAULT_CENTER_POPUP_WIDTH));
//     OCMStub([contextMock numberNamed:LPMT_ARG_LAYOUT_HEIGHT]).andReturn(@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT));
//     OCMStub([contextMock stringNamed:LPMT_ARG_URL_CLOSE]).andReturn(LPMT_DEFAULT_CLOSE_URL);
//     OCMStub([contextMock stringNamed:LPMT_ARG_URL_OPEN]).andReturn(LPMT_DEFAULT_OPEN_URL);
//     OCMStub([contextMock stringNamed:LPMT_ARG_URL_TRACK]).andReturn(LPMT_DEFAULT_TRACK_URL);
//     OCMStub([contextMock stringNamed:LPMT_ARG_URL_ACTION]).andReturn(LPMT_DEFAULT_ACTION_URL);
//     OCMStub([contextMock stringNamed:LPMT_ARG_URL_TRACK_ACTION]).andReturn(LPMT_DEFAULT_TRACK_ACTION_URL);
//     OCMStub([contextMock stringNamed:LPMT_ARG_HTML_ALIGN]).andReturn(LPMT_ARG_HTML_ALIGN_TOP);
//     OCMStub([contextMock numberNamed:LPMT_ARG_HTML_HEIGHT]).andReturn(@0);
//     OCMStub([contextMock stringNamed:LPMT_ARG_HTML_WIDTH]).andReturn(@"100%");
//     OCMStub([contextMock stringNamed:LPMT_ARG_HTML_Y_OFFSET]).andReturn(@"0px");
//     OCMStub([contextMock boolNamed:LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE]).andReturn(NO);
//     OCMStub([contextMock boolNamed:LPMT_HAS_DISMISS_BUTTON]).andReturn(NO);
//     OCMStub([contextMock htmlStringContentsOfFile:[OCMArg any]]).andReturn([self htmlTemplateString]);

//     template.contexts = [@[contextMock] mutableCopy];
//     [template setupPopupView];
//     XCTestExpectation *expects = [self expectationWithDescription:@"wait_for_load"];
//     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 15.0), dispatch_get_main_queue(), ^{
//         if (@available(iOS 11.0, *)) {
//             [template.popupView takeSnapshotWithConfiguration:nil completionHandler:^(UIImage * _Nullable snapshotImage, NSError * _Nullable error) {
//                 UIImageView *imgView = [[UIImageView alloc] initWithImage:snapshotImage];
//                 FBSnapshotVerifyView(imgView, nil);
//                 [expects fulfill];
//             }];
//         } else {
//             // Fallback on earlier versions
//         }
//     });
//     [self waitForExpectationsWithTimeout:20 handler:nil];

}


-(NSString *)htmlTemplateString {
    return @"<!doctype html> <html xmlns=\"http://www.w3.org/1999/xhtml\"> <head> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1, maximum-scale=1\" charset=\"utf-8\"> <style type=\"text/css\">a,abbr,acronym,address,applet,article,aside,audio,b,big,blockquote,body,canvas,caption,center,cite,code,dd,del,details,dfn,div,dl,dt,em,embed,fieldset,figcaption,figure,footer,form,h1,h2,h3,h4,h5,h6,header,hgroup,html,i,iframe,img,ins,kbd,label,legend,li,mark,menu,nav,object,ol,output,p,pre,q,ruby,s,samp,section,small,span,strike,strong,sub,summary,sup,table,tbody,td,tfoot,th,thead,time,tr,tt,u,ul,var,video{margin:0;padding:0;border:0;font-size:100%;font:inherit;vertical-align:baseline}article,aside,details,figcaption,figure,footer,header,hgroup,menu,nav,section{display:block}body{line-height:1}ol,ul{list-style:none}blockquote,q{quotes:none}blockquote:after,blockquote:before,q:after,q:before{content:'';content:none}table{border-collapse:collapse;border-spacing:0}*{-webkit-tap-highlight-color:transparent}*{-webkit-touch-callout:none;-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;user-select:none}html{height:100%}#close-button{display:none;position:absolute;top:5px;right:5px;z-index:10}#cover{z-index:0;position:absolute;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,.5)}.text{text-align:center}.image{background-size:contain;background-repeat:no-repeat;background-position:center}body{height:100%;display:-ms-flexbox;display:flex;-ms-flex-align:center;align-items:center;-ms-flex-pack:center;justify-content:center;font-family:sans-serif;font-weight:400}#view{-ms-flex:1 1 auto;flex:1 1 auto;z-index:1;position:relative;border:1px solid}#view.rounded-border{border-radius:13px}#view.rounded-border #hero-image{border-top-right-radius:13px;border-top-left-radius:13px}#view.rounded-border #hero-image{border-top-right-radius:13px;border-top-left-radius:13px}#view.rounded-border .button-section{overflow:hidden;border-bottom-right-radius:13px;border-bottom-left-radius:13px}@media screen and (device-width :375px) and (device-height :812px) and (-webkit-device-pixel-ratio :3) and (orientation:landscape){html{height:375px!important}}.top-section{height:100%;display:-ms-flexbox;display:flex;-ms-flex-direction:column;flex-direction:column}.text-section{display:-ms-flexbox;display:flex;-ms-flex-direction:column;flex-direction:column;-ms-flex:1 1 auto;flex:1 1 auto;position:relative;margin-top:-72px}.hero-below-headline .text-section{margin-top:-50px}.button-section{position:relative;z-index:10;margin-top:-50px;border-top:1px solid;display:-ms-flexbox;display:flex}#title{line-height:140%;margin-top:20px;padding:0 15px;box-sizing:border-box}.hero-below-headline #title{margin-bottom:20px}#message-wrapper{width:100%;position:absolute;top:50%;transform:translateY(-50%)}#message{line-height:140%;padding:0 15px;box-sizing:border-box}#hero-image{width:100%;margin-left:auto;margin-right:auto;height:140px}#button-1,#button-2{letter-spacing:.03em;-ms-flex:1 1 50%;flex:1 1 50%;height:49px;padding-top:15px;box-sizing:border-box}#button-1:not(:last-child){border-right:1px solid}</style></head><body class=\"vsc-initialized\"><div id=\"view\" class=\"image rounded-border\"><div id=\"close-button\">    <svg width=\"25px\" height=\"25px\" viewBox=\"0 0 60 60\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">      <circle id=\"Oval\" fill=\"#222222\" cx=\"30\" cy=\"30\" r=\"30\"></circle>      <path d=\"M41.1015684,37.532294 C42.3105813,38.7889863 42.3189193,40.8040273 41.1099064,42.065053 C39.9134005,43.308745 37.9664729,43.3174119 36.753291,42.0563862 L29.5033827,34.5248994 L22.2576434,42.0563862 C21.0444615,43.308745 19.1100408,43.3174119 17.901028,42.065053 C16.7003531,40.8126942 16.6961841,38.7976531 17.909366,37.532294 L25.1551053,30.0008072 L17.909366,22.4693205 C16.7086911,21.2169616 16.6961841,19.2019206 17.901028,17.9408949 C19.1017028,16.688536 21.0402925,16.6842026 22.2576434,17.9408949 L29.5033827,25.4723816 L36.753291,17.9408949 C37.9581349,16.6928694 39.9050625,16.6842026 41.1099064,17.9408949 C42.3105813,19.1889203 42.3189193,21.1996279 41.1015684,22.4693205 L33.8599981,30.0008072 L41.1015684,37.532294 Z\" id=\"Close-Icon\" fill=\"#FFFFFF\"></path>    </svg></div>      <div class=\"top-section\">        <div id=\"hero-image\" class=\"image\"></div><div id=\"title\" class=\"text\">This title is Blue</div>                <div class=\"text-section\">          <div id=\"message-wrapper\">            <div id=\"message\" class=\"text\"><div style=\"overflow-y: scroll; height:200px;\">mavi gök, asağıda Тест  две три三園やゆれ司一يكيبيديا،. ثم ليبيIt's a fez. I wear a fez now. Fezzes are cool. Overconfidence, this, and a small screwdriver. I’m absolutely sorted. Geronimo! I need...I need...I need... fish fingers and custard! Father Christmas. Santa Claus. Or, as I’ve always known him, Jeff. Come along, Pond! No idea. Just do what I do: hold tight and pretend it's a plan. Usually called 'The Doctor.' Or 'The Caretaker.' Or 'Get off this planet.' Though, strictly speaking, that probably isn't a name. Frightened people. Give me a Dalek any day.I know. Dinosaurs! On a spaceship! Thank you, Strax. And if I'm ever in need of advice from a psychotic potato dwarf, you'll certainly be the first to know. Please tell me I didn't get old. Anything but old. I was young! Oh... is he grey? Bow ties are cool. Oh, I always rip out the last page of a book. Then it doesn't have to end. I hate endings! I once spent a hell of a long time trying to get a gobby Australian to Heathrow airport. Come along, Pond! Goodbye, Clara. There's something that doesn't make sense. Let's go and poke it with a stick.Geronimo! I once spent a hell of a long time trying to get a gobby Australian to Heathrow airport. I know. Dinosaurs! On a spaceship! Oh, I always rip out the last page of a book. Then it doesn't have to end. I hate endings! You are the only mystery worth solving. There are fixed points throughout time where things must stay exactly the way they are. This is not one of them. This is an opportunity! Whatever happens here will create its own timeline, its own reality, a temporal tipping point. The future revolves around you, here, now, so do good!Bow ties are cool. Oh, I always rip out the last page of a book. Then it doesn't have to end. I hate endings! Look at me. No plans, no backup, no weapons worth a damn. Oh, and something else I don't have: anything to lose. So, if you're sitting up there with your silly little spaceships and your silly little guns and you've any plans on taking the Pandorica tonight; just remember who's standing in your way. Remember every black day I ever stopped you and then, and then, do the smart thing. Let somebody else try first.نYou are the only mystery worth solving. No idea. Just do what I do: hold tight and pretend it's a plan. Overconfidence, this, and a small screwdriver. I’m absolutely sorted. Bow ties are cool. Thank you, Strax. And if I'm ever in need of advice from a psychotic potato dwarf, you'll certainly be the first to know. I once spent a hell of a long time trying to get a gobby Australian to Heathrow airport. Goodbye, Clara. I need...I need...I need... fish fingers and custard! I know. Dinosaurs! On a spaceship!</div></div>          </div>        </div>      </div>      <div class=\"button-section\">        <div id=\"button-1\" class=\"text image\">Button 1</div>        <div id=\"button-2\" class=\"text image\">Button 2</div>      </div>    </div>    <div id=\"cover\"></div><style>body{font-family:sf_ui;}#view{height:100%;}#view{max-width:100%;}#close-button{display:block !important;}#hero-image{display:block;}#hero-image{background-image:url(https://vignette.wikia.nocookie.net/powerlisting/images/b/b4/Matt-Smith-as-the-11th-Doctor.jpg/revision/latest/scale-to-width-down/185?cb=20120628063239);}#hero-image{width:100%;}#hero-image{height:140px;}#view{background-color:rgba(238,238,238,1);}#view{background-image:url();}#view{border-color:rgba(0,0,0,1);}#view{border-width:0px;}#title{color:rgba(0,29,184,1);}#title{font-size:16px;}#title{font-weight:600;}#title{width:100%;}#title{text-align:center;}#message{color:rgba(242,41,41,1);}#message{font-size:14px;}#message{font-style:italic;}#message{width:100%;}#message{text-align:center;}.button-section{border-color:rgba(216,216,216,1);}#button-1{border-color:rgba(216,216,216,1) !important;}#button-1{background-color:rgba(255,255,255,0);}#button-1:active{background-color:rgba(229,235,237,1);}#button-1{background-image:url();}#button-1:active{background-image:url();}#button-1{color:rgba(68,149,244,1);}#button-1{font-size:16px;}#button-2{background-color:rgba(255,255,255,0);}#button-2:active{background-color:rgba(229,235,237,1);}#button-2{background-image:url();}#button-2:active{background-image:url();}#button-2{color:rgba(68,149,244,1);}#button-2{font-size:16px;}</style> </body></html>";
}

@end
