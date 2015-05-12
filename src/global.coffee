Status =
  unavailable:
    buttonEnabled: no
    buttonToolTip: 'TimeEnforcement not available on this tab'
    buttonIcon: 'IconUnavailable.png'
    buttonIconHiRes: 'IconUnavailable@2x.png'
  disabled:
    buttonEnabled: yes
    buttonToolTip: 'Enable TimeEnforcement'
    buttonIcon: 'IconDisabled.png'
    buttonIconHiRes: 'IconDisabled@2x.png'
  enabled:
    buttonEnabled: yes
    buttonToolTip: 'TimeEnforcement is anabled, click to disable'
    buttonIcon: 'IconEnabled.png'
    buttonIconHiRes: 'IconEnabled@2x.png'

class TabState
  constructor: (@tab)->
    @enabled = no
    @timeEnforcementAt = "2015-10-18"

  enablePageAction: ->
    chrome.pageAction.show(@tab.id)
    chrome.pageAction.setTitle({ tabId: @tab.id, title: "TimeEnforcement: Available" })
    chrome.pageAction.onClicked.addListener(toggleTimeEnforcement)

  toggleTimeEnforcement: ->
    if @enabled
      @disable(@tab)
    else
      @enable(@tab)

  disable: ->
    chrome.webRequest.onBeforeSendHeaders.removeListener(@addTimeEnforcementAt)
    chrome.pageAction.setTitle({ tabId: @tab.id, title: "TimeEnforcement: Disabled" })

  addTimeEnforcementAt: (info)->
    headers = info.requestHeaders
    headers.push
      "name": "Time-Enforcement-At"
      "value": @timeEnforcementAt

    { requestHeaders: headers }

  enable: ->
    chrome.webRequest.onBeforeSendHeaders.addListener @addTimeEnforcementAt,
      tabId: @tab.id
      urls: [
        "<all_urls>"
      ]
      types: ["main_frame", "sub_frame", "xmlhttprequest"]
    ,
      [ "blocking", "requestHeaders" ]
    chrome.pageAction.setTitle({ tabId: @tab.id, title: "TimeEnforcement: Enabled" })

TimeEnforcementGlobal =
  _tabs: []


chrome.webRequest.onCompleted.addListener (info) ->
  headers = info.responseHeaders
  headers.forEach (header, i)->
    if header.name == "Time-Enforcement-Available" and header.value == "true"
      enableTimeEnforcement(info.tabId)
,
  urls: [
    "<all_urls>"
  ]
,
[ "responseHeaders" ]
