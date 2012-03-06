// Copyright 2009 Google Inc. All Rights Reserved.
// You may study, modify, and use this example for any purpose.
// Note that this example is provided "as is", WITHOUT WARRANTY
// of any kind either expressed or implied.
package com.google.ads.examples.flex.instream_netstream {
  import com.google.ads.instream.api.Ad;
  import com.google.ads.instream.api.AdError;
  import com.google.ads.instream.api.AdErrorEvent;
  import com.google.ads.instream.api.AdEvent;
  import com.google.ads.instream.api.AdLoadedEvent;
  import com.google.ads.instream.api.AdSizeChangedEvent;
  import com.google.ads.instream.api.AdTypes;
  import com.google.ads.instream.api.AdsLoadedEvent;
  import com.google.ads.instream.api.AdsLoader;
  import com.google.ads.instream.api.AdsManager;
  import com.google.ads.instream.api.AdsManagerTypes;
  import com.google.ads.instream.api.AdsRequest;
  import com.google.ads.instream.api.AdsRequestType;
  import com.google.ads.instream.api.CompanionAd;
  import com.google.ads.instream.api.CompanionAdEnvironments;
  import com.google.ads.instream.api.CustomContentAd;
  import com.google.ads.instream.api.FlashAd;
  import com.google.ads.instream.api.FlashAdCustomEvent;
  import com.google.ads.instream.api.FlashAdsManager;
  import com.google.ads.instream.api.HtmlCompanionAd;
  import com.google.ads.instream.api.VastVideoAd;
  import com.google.ads.instream.api.VastWrapper;
  import com.google.ads.instream.api.VideoAd;
  import com.google.ads.instream.api.VideoAdsManager;

  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.geom.Point;
  import flash.media.Video;
  import flash.net.NetConnection;
  import flash.net.NetStream;

  import mx.core.Application;
  import mx.core.UIComponent;

  public class SamplePlayer extends Sprite {
    private static const CONTENT_URL:String = "http://rmcdn.2mdn.net/Demo/" +
        "FLV/content.flv";

    /**
     * The following constants are used for pre-defined test scenarios in
     * setTestValuesInDropDown() method.
     */
    private static const VIDEO_AD_AFV:String = "AFV video ad";
    private static const TEXT_AD_AFV:String = "AFV text ad";
    private static const FULLSLOT_AD_AFV:String = "AFV Full Slot";
    private static const VIDEO_AD_AFV_WINS:String = "Dynamic Allocation where" +
        " AFV video wins";
    private static const VIDEO_AD_COMPANIONS_DCLK_WINS:String = "Dynamic" +
        " Allocation where DoubleClick InStream ad with HTML companions wins";
    private static const FLASH_AD_DCLK_WINS:String = "Dynamic Allocation" +
        " where DoubleClick Flash-in-Flash ad wins";
    private static const TEXT_AD_AFV_WINS:String = "Dynamic Allocation where" +
        " AFV text overlay wins";
    private static const IMAGE_AD_AFV_WINS:String = "Dynamic Allocation" +
        " where AFV image ad wins";
    private static const FLASH_AD_COMPANIONS_DCLK_WINS:String = "Dynamic" +
        " Allocation where DoubleClick Flash-in-Flash ad with HTML" +
        " companions wins";
    private static const VIDEO_AD_DCLK:String = "DoubleClick InStream video ad";
    private static const VAST_DCLK:String = "DoubleClick VAST 2.0 ad with" +
        " companions";
    private static const FLASH_AD_DCLK:String = "DoubleClick Flash-In-Flash ad";
    // WRITE_INTO_COMPANION_DIV is a javascript function defined in the HTML
    // page.
    private static const WRITE_INTO_COMPANION_DIV:String =
        "writeIntoCompanionDiv";
    private static const FALSE:String = "false";

    private var adsManager:AdsManager;
    private var adsLoader:AdsLoader;
    private var currentNetStream:NetStream;
    private var contentNetStream:NetStream;
    private var flashVars:Object;
    private var video:Video;
    private var useGUT:Boolean;

    /**
    * The toplevel application, used to acces UI components.
    */
    private var flexApplication:Object;

    /**
    * <code>flexApplication</code> should be the top level Flex application
    * where your UI controls are and where you want ads and video to be
    * displayed.
    */
    public function SamplePlayer(flexApplication:Object) {
      this.flexApplication = flexApplication;
      initialize();
    }

    private function initialize():void {
      removeEventListener(Event.ADDED_TO_STAGE, initialize);
      flexApplication.testChooser.addEventListener(Event.CHANGE, setTest);
      flexApplication.loadAdButton.addEventListener(MouseEvent.CLICK,
                                                    onLoadAdButtonClick);
      flexApplication.unloadAdButton.addEventListener(MouseEvent.CLICK,
                                          onUnloadAdButtonClick);

      flexApplication.playButton.addEventListener(MouseEvent.CLICK, playVideo);
      flexApplication.pauseButton.addEventListener(MouseEvent.CLICK,
                                                   pauseVideo);
      flexApplication.stopButton.addEventListener(MouseEvent.CLICK, stopVideo);

      initializeTestChooser();
      setAdTypeValuesInDropDown();
    }

    private function onLoadAdButtonClick(event:Event):void {
      cleanup();
      playContent();
      loadAd();
    }

    /**
     * Creates the AdsLoader object if its not present
     * and request ads using the AdsLoader object.
     */
    private function loadAd():void {
      if (!adsLoader) {
        adsLoader = new AdsLoader();
        flexApplication.stage.addChild(adsLoader);
        adsLoader.addEventListener(AdsLoadedEvent.ADS_LOADED, onAdsLoaded);
        adsLoader.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
      }

      adsLoader.requestAds(createAdsRequest());
      log("Ad requested");
    }

    /**
     * This method is used to create the AdsRequest object which is used by the
     * AdsLoader to request ads.
     */
    private function createAdsRequest():AdsRequest {
      var request:AdsRequest = new AdsRequest();
      request.adSlotWidth = parseInt(flexApplication.adSlotWidthTextInput.text);
      request.adSlotHeight =
          parseInt(flexApplication.adSlotHeightTextInput.text);
      request.adTagUrl = flexApplication.adTagUrlTextInput.text;
      request.adType = flexApplication.adTypeChooser.selectedItem.data;
      if (flexApplication.channelsTextInput.text) {
        request.channels = flexApplication.channelsTextInput.text.split(",");
      }
      if (flexApplication.contentIdCheckbox.selected) {
        request.contentId = flexApplication.contentIdTextInput.text;
      }
      if (flexApplication.publisherIdCheckbox.selected) {
        request.publisherId = flexApplication.publisherIdTextInput.text;
      }
      if (flexApplication.disableCompanionsCheckbox.selected) {
        request.disableCompanionAds = true;
      }
      if (flexApplication.maxAdDurationTextInput.text &&
          flexApplication.maxAdDurationTextInput.text.length > 0) {
        request.maxTotalAdDuration =
            parseInt(flexApplication.maxAdDurationTextInput.text);
      }
      // Checks the companion type from flashVars to decides whether to use GUT
      // or getCompanionAds() to load companions.
      flashVars = Application.application.parameters;
      useGUT = flashVars != null && flashVars.useGUT == FALSE ? false : true;
      if (!useGUT) {
        request.disableCompanionAds = true;
      }
      return request;
    }

    /**
     * This method is invoked when the adsLoader has completed loading an ad
     * using the adsRequest object provided.
     */
    private function onAdsLoaded(adsLoadedEvent:AdsLoadedEvent):void {
      log("Ads Loaded");
      adsManager = adsLoadedEvent.adsManager;
      adsManager.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
      adsManager.addEventListener(AdEvent.CONTENT_PAUSE_REQUESTED,
                                  onContentPauseRequested);
      adsManager.addEventListener(AdEvent.CONTENT_RESUME_REQUESTED,
                                  onContentResumeRequested);
      adsManager.addEventListener(AdLoadedEvent.LOADED, onAdLoaded);
      adsManager.addEventListener(AdEvent.STARTED, onAdStarted);
      adsManager.addEventListener(AdEvent.CLICK, onAdClicked);

      resetPlayerState();
      displayAdsInformation(adsManager);

      if (adsManager.type == AdsManagerTypes.FLASH) {
        var flashAdsManager:FlashAdsManager = adsManager as FlashAdsManager;
        flashAdsManager.addEventListener(AdSizeChangedEvent.SIZE_CHANGED,
                                         onFlashAdSizeChanged);
        flashAdsManager.addEventListener(FlashAdCustomEvent.CUSTOM_EVENT,
                                         onFlashAdCustomEvent);

        var videoPlaceHolder:UIComponent = flexApplication.videoPlaceHolder;
        var point:Point =
            videoPlaceHolder.localToGlobal(new Point(videoPlaceHolder.x,
                                                     videoPlaceHolder.y));
        log("Setting x, y co-ordinates for the Flash ad slot to (" + point.x +
            ", " + point.y + ").");
        flashAdsManager.x = point.x;
        flashAdsManager.y = point.y;

        log("Calling load, then play");
        flashAdsManager.load();
        flashAdsManager.play();
      } else if (adsManager.type == AdsManagerTypes.VIDEO) {
        var videoAdsManager:VideoAdsManager = adsManager as VideoAdsManager;
        videoAdsManager.addEventListener(AdEvent.STOPPED,
                                         onVideoAdStopped);
        videoAdsManager.addEventListener(AdEvent.PAUSED,
                                         onVideoAdPaused);
        videoAdsManager.addEventListener(AdEvent.COMPLETE,
                                         onVideoAdComplete);
        videoAdsManager.addEventListener(AdEvent.MIDPOINT,
                                         onVideoAdMidpoint);
        videoAdsManager.addEventListener(AdEvent.FIRST_QUARTILE,
                                         onVideoAdFirstQuartile);
        videoAdsManager.addEventListener(AdEvent.THIRD_QUARTILE,
                                         onVideoAdThirdQuartile);
        videoAdsManager.addEventListener(AdEvent.RESTARTED,
                                         onVideoAdRestarted);
        videoAdsManager.addEventListener(AdEvent.VOLUME_MUTED,
                                         onVideoAdVolumeMuted);
        log("Setting click tracking");
        videoAdsManager.clickTrackingElement = flexApplication.videoPlaceHolder;
        log("Calling load, then play");
        videoAdsManager.load(video);
        videoAdsManager.play(video);
      } else if (adsManager.type == AdsManagerTypes.CUSTOM_CONTENT) {
        // Cannot call play() since it is custom content.
        // You can get the content string from the ad and further process it as
        // required.
        for each (var ad:CustomContentAd in adsManager.ads) {
          log(ad.content);
        }
      }
    }

    private function playContent():void {
      var nc:NetConnection = new NetConnection();
      nc.connect(null);
      var customClient:Object = new Object();
      customClient.onMetaData = metaDataHandler;
      contentNetStream = new NetStream(nc);
      currentNetStream = contentNetStream;
      contentNetStream.client = customClient;

      video = new Video();
      video.width = flexApplication.videoPlaceHolder.width;
      video.height = flexApplication.videoPlaceHolder.height;
      video.attachNetStream(contentNetStream);
      flexApplication.videoPlaceHolder.addChild(video);

      contentNetStream.play(CONTENT_URL);
    }

    /**
     * This method is invoked when an interactive flash ad raises the
     * contentPauseRequested event.
     *
     * We recommend that publishers pause their video content when this method
     * is invoked. This is usually because the ad will play within the video
     * player itself or cover the video player so that the publisher content
     * would not be easily visible.
     */
    private function onContentPauseRequested(event:AdEvent):void {
      logEvent(event.type);
      if (contentNetStream) {
        contentNetStream.pause();
      }
    }

    /**
     * This method is invoked when an interactive flash ad raises the
     * contentResumeRequested event.
     *
     * We recommend that publishers resume their video content when this method
     * is invoked. This is because the ad has completed playing and the
     * publisher content should be resumed from the time it was paused.
     */
    private function onContentResumeRequested(event:AdEvent):void {
      logEvent(event.type);
      if (contentNetStream) {
        // Resume the content from the position where it was paused.
        video.attachNetStream(contentNetStream);
        currentNetStream = contentNetStream;
        contentNetStream.resume();
      } else {
        // Play content after the ad has finished playing.
        playContent();
      }
    }

    private function onAdStarted(event:AdEvent):void {
      logEvent(event.type);
    }

    private function onAdClicked(event:AdEvent):void {
      logEvent(event.type);
    }

    private function onAdLoaded(event:AdLoadedEvent):void {
      logEvent(event.type);
      if (event.netStream) {
        currentNetStream = event.netStream;
      }
    }

    private function onFlashAdSizeChanged(event:AdSizeChangedEvent):void {
      logEvent(event.type);
    }

    private function onFlashAdCustomEvent(event:FlashAdCustomEvent):void {
      logEvent(event.type);
    }

    private function onVideoAdStopped(event:AdEvent):void {
      logEvent(event.type);
    }

    private function onVideoAdPaused(event:AdEvent):void {
      logEvent(event.type);
    }

    private function onVideoAdMidpoint(event:AdEvent):void {
      logEvent(event.type);
    }

    private function onVideoAdFirstQuartile(event:AdEvent):void {
      logEvent(event.type);
    }

    private function onVideoAdThirdQuartile(event:AdEvent):void {
      logEvent(event.type);
    }

    private function onVideoAdClicked(event:AdEvent):void {
      logEvent(event.type);
    }

    private function onVideoAdRestarted(event:AdEvent):void {
      logEvent(event.type);
    }

    private function onVideoAdVolumeMuted(event:AdEvent):void {
      logEvent(event.type);
    }

    /**
     * This method is invoked when the video ad loaded using the Google
     * In-Stream SDK has completed playing.
     */
    private function onVideoAdComplete(event:AdEvent):void {
      logEvent(event.type);
      removeListeners();
      // Remove clickTrackingElement before playing content or a different ad.
      if (adsManager.type == AdsManagerTypes.VIDEO) {
        (adsManager as VideoAdsManager).clickTrackingElement = null;
      }
    }

    private function metaDataHandler(infoObject:Object):void {
      log("content metadata");
    }

    private function onAdError(adErrorEvent:AdErrorEvent):void {
      var adError:AdError = adErrorEvent.error;
      log("Ad error: " + adError.errorMessage);
      if (adError.innerError != null) {
        log("Caused by: " + adError.innerError.message);
      }
    }

    /**
     * This method is used to log information regarding the AdsManager and
     * the Ad objects.
     *
     * Publishers will usually not need to do this unless they are interested
     * in logging or otherwise processing data about the ads.
     */
    private function displayAdsInformation(adsManager:Object):void {
      log("AdsManager type: " + adsManager.type);
      var ads:Array = adsManager.ads;
      if (ads) {
        log(ads.length + " ads loaded");
        for each (var ad:Ad in ads) {
          try {
            // APIs defined on Ad
            log("type: " + ad.type);
            log("id: " + ad.id);
            log("traffickingParameters: " + ad.traffickingParameters);
            log("surveyUrl: " + ad.surveyUrl);
            // Check the companion type from flashVars to decide whether to use
            // GUT or getCompanionAds() to load companions.
            if (!useGUT) {
              renderHtmlCompanionAd(
                  ad.getCompanionAds(CompanionAdEnvironments.HTML, 300, 250),
                  "300x250");
              renderHtmlCompanionAd(
                  ad.getCompanionAds(CompanionAdEnvironments.HTML, 728, 90),
                  "728x90");
            }
            if (ad.type == AdTypes.VAST) {
              var vastAd:VastVideoAd = ad as VastVideoAd;
              log("description: " + vastAd.description);
              log("adSystem: " + vastAd.adSystem);
              log("customClicks: " + vastAd.customClicks);
            } else if (ad.type == AdTypes.VIDEO) {
              // APIs defined on all video ads
              var videoAd:VideoAd = ad as VideoAd;
              log("author: " + videoAd.author);
              log("title: " + videoAd.title);
              log("ISCI: " + videoAd.ISCI);
              log("deliveryType: " + videoAd.deliveryType);
              log("mediaUrl: " + videoAd.mediaUrl);
              // getCompanionAdUrl will throw error for VAST ads.
              log("getCompanionAdUrl: " + ad.getCompanionAdUrl("flash"));
            } else if (ad.type == AdTypes.FLASH) {
              // API defined on FlashAd
              var flashAd:FlashAd = ad as FlashAd;
              if (flashAd.asset != null) {
                log("asset: " + flashAd.asset);
                log("asset x: " + flashAd.asset.x);
                log("asset y: " + flashAd.asset.y);
                log("asset height: " + flashAd.asset.height);
                log("asset width: " + flashAd.asset.width);
              } else {
                log("Error: flashAsset is null.");
              }
            }
          } catch (error:Error) {
            log("Error type:" + error + " message:" + error.message);
          }
        }
      }
    }

    private function renderHtmlCompanionAd(companionArray:Array,
                                           size:String):void {
      if (companionArray.length > 0) {
        log("There are " + companionArray.length + " companions for this ad.");
        var companion:CompanionAd = companionArray[0] as CompanionAd;
        if (companion.environment == CompanionAdEnvironments.HTML) {
          log("companion " + size + " environment: " + companion.environment);
          var htmlCompanion:HtmlCompanionAd = companion as HtmlCompanionAd;
          if(ExternalInterface.available) {
            ExternalInterface.call(WRITE_INTO_COMPANION_DIV,
                                   htmlCompanion.content,
                                   size);
          }
        }
      }
    }

    private function cleanup():void {
      onUnloadAdButtonClick();
    }

    private function onUnloadAdButtonClick(event:Event = null):void {
      unloadAd();
      clearVideo();
    }

    private function unloadAd():void {
      try {
        if (adsManager) {
          removeListeners();
          removeAdsManagerListeners();
          adsManager.unload();
          adsManager = null;
          log("Ad unloaded");
        }
      } catch (e:Error) {
        log("Error occured during unload : " + e.message + e.getStackTrace());
      }
    }

    private function clearVideo():void {
      if (video && currentNetStream) {
        currentNetStream.close();
        video.clear();
      }
    }

    private function removeListeners():void {
      adsManager.removeEventListener(AdLoadedEvent.LOADED, onAdLoaded);
      adsManager.removeEventListener(AdEvent.STARTED, onAdStarted);

      if (adsManager.type == AdsManagerTypes.VIDEO) {
        var videoAdsManager:VideoAdsManager = adsManager as VideoAdsManager;
        videoAdsManager.removeEventListener(AdEvent.STOPPED,
                                            onVideoAdStopped);
        videoAdsManager.removeEventListener(AdEvent.PAUSED,
                                            onVideoAdPaused);
        videoAdsManager.removeEventListener(AdEvent.COMPLETE,
                                            onVideoAdComplete);
        videoAdsManager.removeEventListener(AdEvent.MIDPOINT,
                                            onVideoAdMidpoint);
        videoAdsManager.removeEventListener(AdEvent.FIRST_QUARTILE,
                                            onVideoAdFirstQuartile);
        videoAdsManager.removeEventListener(AdEvent.THIRD_QUARTILE,
                                            onVideoAdThirdQuartile);
        videoAdsManager.removeEventListener(AdEvent.RESTARTED,
                                            onVideoAdRestarted);
        videoAdsManager.removeEventListener(AdEvent.VOLUME_MUTED,
                                            onVideoAdVolumeMuted);
      } else if (adsManager.type == AdsManagerTypes.FLASH) {
        var flashAdsManager:FlashAdsManager = adsManager as FlashAdsManager;
        flashAdsManager.removeEventListener(
            AdSizeChangedEvent.SIZE_CHANGED, onFlashAdSizeChanged);
        flashAdsManager.removeEventListener(
            FlashAdCustomEvent.CUSTOM_EVENT, onFlashAdCustomEvent);
      }
    }

    private function removeAdsManagerListeners():void {
      adsManager.removeEventListener(AdErrorEvent.AD_ERROR, onAdError);
      adsManager.removeEventListener(AdEvent.CONTENT_PAUSE_REQUESTED,
                                     onContentPauseRequested);
      adsManager.removeEventListener(AdEvent.CONTENT_RESUME_REQUESTED,
                                     onContentResumeRequested);
      adsManager.removeEventListener(AdEvent.CLICK, onAdClicked);
    }

    private var paused:Boolean;
    private var muted:Boolean;
    private var playing:Boolean;
    private var stopped:Boolean;

    private function resetPlayerState():void {
      paused = false;
      playing = false;
      stopped = false;
      muted = false;
    }

    private function playVideo(event:Event):void {
      log("Play called");
      if (stopped) {
        stopped = false;
      }
      playing = true;
      paused = false;
      if (currentNetStream == null) {
        playContent();
      } else {
        currentNetStream.resume();
      }
    }

    private function pauseVideo(event:Event):void {
      log("Pause called");
      if (stopped) {
        return;
      }
      paused = !paused;
      if (paused) {
        playing = false;
        currentNetStream.pause();
      } else {
        playing = true;
        currentNetStream.resume();
      }
    }

    private function stopVideo(event:Event):void {
      log("Stop called");
      stopped = true;
      playing = false;
      currentNetStream.pause();
      currentNetStream.seek(0);
    }

    private function log(message:Object):void {
      flexApplication.logTextArea.text += message + "\n";
      flexApplication.logTextArea.verticalScrollPosition =
          flexApplication.logTextArea.maxVerticalScrollPosition;
    }

    private function logEvent(eventType:String):void {
      log(eventType + " event raised");
    }

    /**
     * This method is used to set up input values for the ads being
     * requested in the text fields displayed in the UI.
     */
    private function setTestValues(adSlotWidth:String,
                                   adSlotHeight:String,
                                   adTagUrl:String,
                                   adType:String,
                                   channels:String,
                                   contentId:String,
                                   publisherId:String,
                                   disableCompanions:Boolean):void {
      setTextField(flexApplication.adSlotWidthTextInput, adSlotWidth);
      setTextField(flexApplication.adSlotHeightTextInput, adSlotHeight);
      setTextField(flexApplication.adTagUrlTextInput, adTagUrl);
      flexApplication.adTypeChooser.selectedIndex =
          getItemIndexForLabel(adType);
      if (contentId != null) {
        flexApplication.contentIdCheckbox.selected = true;
        setTextField(flexApplication.contentIdTextInput, contentId);
      } else {
        flexApplication.contentIdCheckbox.selected = false;
        setTextField(flexApplication.contentIdTextInput);
      }
      if (publisherId != null) {
        flexApplication.publisherIdCheckbox.selected = true;
        setTextField(flexApplication.publisherIdTextInput, publisherId);
      } else {
        flexApplication.publisherIdCheckbox.selected = false;
        setTextField(flexApplication.publisherIdTextInput);
      }
      flexApplication.disableCompanionsCheckbox.selected = disableCompanions;
      setTextField(flexApplication.channelsTextInput, channels);
    }

    private function setTextField(uiTextInput:Object, text:String = ""):void {
      uiTextInput.text = text;
    }

    /**
     * This method is used to retrive the index values for the adType drop down
     * in the UI.
     */
    private function getItemIndexForLabel(data:String):uint {
      var adTypeChooser:Object = flexApplication.adTypeChooser.dataProvider;
      for (var i:uint = 0; i < adTypeChooser.length; i++) {
        var item:Object = adTypeChooser.getItemAt(i);
        if (item.data == data) {
          return i;
        }
      }
      return null;
    }

    /**
     * This method is used to populate the dropdown values in the UI.
     */
    private function initializeTestChooser():void {
      var dataProvider:Array =
        [{label: "Choose which scenario to run"},
        {label: VIDEO_AD_AFV},
        {label: TEXT_AD_AFV},
        {label: FULLSLOT_AD_AFV},
        {label: VIDEO_AD_AFV_WINS},
        {label: VIDEO_AD_COMPANIONS_DCLK_WINS},
        {label: FLASH_AD_DCLK_WINS},
        {label: TEXT_AD_AFV_WINS},
        {label: IMAGE_AD_AFV_WINS},
        {label: FLASH_AD_COMPANIONS_DCLK_WINS},
        {label: VIDEO_AD_DCLK},
        {label: VAST_DCLK},
        {label: FLASH_AD_DCLK}];
      flexApplication.testChooser.dataProvider = dataProvider;
    }

    /**
     * This method is used to populate the adType dropdown values in the UI.
     */
    private function setAdTypeValuesInDropDown():void {
      var dataProvider:Array =
        [{label: "Choose adType value:"},
         {label: "Video", data: AdsRequestType.VIDEO},
         {label: "Text Overlay", data: AdsRequestType.TEXT_OVERLAY},
         {label: "Text Full Slot", data: AdsRequestType.TEXT_FULL_SLOT},
         {label: "Graphical", data: AdsRequestType.GRAPHICAL},
         {label: "Graphical Overlay", data: AdsRequestType.GRAPHICAL_OVERLAY},
         {label: "Graphical Full Slot",
          data: AdsRequestType.GRAPHICAL_FULL_SLOT},
         {label: "Text or Graphical", data: AdsRequestType.TEXT_OR_GRAPHICAL},
         {label: "Full Slot", data: AdsRequestType.FULL_SLOT},
         {label: "Overlay", data: AdsRequestType.OVERLAY}];
      flexApplication.adTypeChooser.dataProvider = dataProvider;
    }

    /**
     * This method is used to set the ad request parameters based on the value
     * selected in the dropdown in the UI.
     */
    private function setTest(event:Event):void {
      log(event.currentTarget.selectedItem.label);
      switch (event.currentTarget.selectedLabel) {
        case VIDEO_AD_AFV:
          setTestValues("450", // adSlotWidth
                        "250", // adSlotHight
                        "", // adTagUrl
                        AdsRequestType.VIDEO, // adType
                        "", // channels
                        "123", // contentId
                        "ca-video-googletest1", // publisherId
                        false); // disableCompanionAds
          break;
        case TEXT_AD_AFV:
          setTestValues("450", // adSlotWidth
                        "250", // adSlotHight
                        "", // adTagUrl
                        AdsRequestType.TEXT_OVERLAY, // adType
                        "", // channels
                        "123", // contentId
                        "ca-video-googletest1", // publisherId
                        false); // disableCompanionAds
          break;
        case FULLSLOT_AD_AFV:
          setTestValues("400", // adSlotWidth
                        "250", // adSlotHight
                        "", // adTagUrl
                        AdsRequestType.GRAPHICAL_FULL_SLOT, // adType
                        "", // channels
                        "123", // contentId
                        "ca-video-googletest1", // publisherId
                        false); // disableCompanionAds
          break;
        case VIDEO_AD_AFV_WINS:
          setTestValues("300", // adSlotWidth
                        "250", // adSlotHight
                        "http://ad.doubleclick.net/pfadx/AngelaSite;" +
                        "foo=prodtest;sz=728x90;dcmt=text/html", // adTagUrl
                        AdsRequestType.VIDEO, // adType
                        "", // channels
                        "123", // contentId
                        null, // publisherId
                        false); // disableCompanionAds
          break;
        case VIDEO_AD_COMPANIONS_DCLK_WINS:
          setTestValues("500", // adSlotWidth
                        "500", // adSlotHight
                        "http://ad.doubleclick.net/pfadx/AngelaSite;" +
                        "foo=instreamwins;sz=728x90;dcmt=text/html", // adTagUrl
                        AdsRequestType.VIDEO, // adType
                        "angela", // channels
                        "123", // contentId
                        null, // publisherId
                        false); // disableCompanionAds
          break;
        case FLASH_AD_DCLK_WINS:
          setTestValues("500", // adSlotWidth
                        "500", // adSlotHight
                        "http://ad.doubleclick.net/pfadx/AngelaSite;" +
                        "kw=dclkf2f;sz=120x350;ord=3577745;dcmt=text/html",
                        // adTagUrl
                        AdsRequestType.OVERLAY, // adType
                        "angela", // channels
                        "123", // contentId
                        null, // publisherId
                        true); // disableCompanionAds
          break;
        case TEXT_AD_AFV_WINS:
          setTestValues("450", // adSlotWidth
                        "250", // adSlotHight
                        "http://ad.doubleclick.net/pfadx/AngelaSite;" +
                        "foo=prodtest;sz=728x90;dcmt=text/html", // adTagUrl
                        AdsRequestType.TEXT_OVERLAY, // adType
                        "", // channels
                        "123", // contentId
                        null, // publisherId
                        false); // disableCompanionAds
          break;
        case IMAGE_AD_AFV_WINS:
          setTestValues("300", // adSlotWidth
                        "250", // adSlotHight
                        "http://ad.doubleclick.net/pfadx/AngelaSite;" +
                        "foo=prodtest;sz=728x90;dcmt=text/html", // adTagUrl
                        AdsRequestType.GRAPHICAL_FULL_SLOT, // adType
                        "", // channels
                        "123", // contentId
                        null, // publisherId
                        false); // disableCompanionAds
          break;
        case FLASH_AD_COMPANIONS_DCLK_WINS:
          setTestValues("300", // adSlotWidth
                        "250", // adSlotHight
                        "http://ad.doubleclick.net/pfadx/AngelaSite;" +
                        "foo=f2fwins;sz=728x90;dcmt=text/html", // adTagUrl
                        AdsRequestType.OVERLAY, // adType
                        "angela", // channels
                        "123", // contentId
                        null, // publisherId
                        false); // disableCompanionAds
          break;
        case VIDEO_AD_DCLK:
          setTestValues("500", // adSlotWidth
                        "500", // adSlotHight
                        "http://ad.doubleclick.net/pfadx/AngelaSite;" +
                        "kw=dclkvideo;sz=120x350;ord=3577745;dcmt=text/html",
                        // adTagUrl
                        AdsRequestType.VIDEO, // adType
                        "", // channels
                        null, // contentId
                        null, // publisherId
                        false); // disableCompanionAds
          break;
        case VAST_DCLK:
          setTestValues("500", // adSlotWidth
                        "500", // adSlotHight
                        "http://ad.doubleclick.net/pfadx/N270.132652." +
                        "1516607168321/B3442378.3;dcadv=1379578;sz=0x0;" +
                        "ord=3577745;dcmt=text/xml", // adTagUrl
                        AdsRequestType.VIDEO, // adType
                        "", // channels
                        null, // contentId
                        null, // publisherId
                        false); // disableCompanionAds
          break;
        case FLASH_AD_DCLK:
          setTestValues("500", // adSlotWidth
                        "500", // adSlotHight
                        "http://ad.doubleclick.net/pfadx/AngelaSite;" +
                        "kw=dclkf2f;sz=120x350;ord=3577745;dcmt=text/html",
                        // adTagUrl
                        AdsRequestType.OVERLAY, // adType
                        "", // channels
                        null, // contentId
                        null, // publisherId
                        false); // disableCompanionAds
          break;
        default:
          log("Unknown test");
      }
    }
  }
}