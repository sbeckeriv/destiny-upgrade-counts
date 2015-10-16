class Shopper
  baseVenderUrl: window.location.protocol+"//www.bungie.net/en/Vendors/ACCOUNT_TYPE/ACCOUNT_ID_SUB/CHARACTER_ID_SUB?vendor=VENDOR_ID&category=2"
  constructor: ->
    @accountID = null
    @characterID = ko.observable(null)
    @accountType = null
    @pageLoading= ko.observable(false)
    @have = ko.observableArray()
    @selling = ko.observableArray()
    @error = ko.observable(false)
    @vendor_names =
      134701236: "Outfitter"
      459708109: "Shipwright"
      2420628997: "Shader"
      2244880194: "Ship"
      44395194: "Sparrow"
      3301500998: "Emblem"
      2668878854: "Vanguard Quartermaster"
      3658200622: "Crucible Quartermaster"
      1998812735: "Variks (Reef)"
      1410745145: "Petra (Reef)"

    @setIDs()
    setInterval(=>
      loading = bnet._pageController.isLoadingPage
      if loading != @pageLoading()
        @pageLoading(loading)
    , 500)
    @buy_list = ko.computed( =>
      list = []
      for item in @selling()
        found = false
        for have_item in @have()
          if have_item["title"] == item["title"] && (have_item["requirements"].match("1/1") || have_item["requirements"].match("2/2")|| have_item["requirements"]=="") # figure out 3/3 later
            found = true
        if !found
          list.push item
      @group_by(list, "vendor_name")
    )
    @buy_types = ko.computed( =>
      names=[]
      list = @selling().filter( (item, index) =>
        names.push(item["vendor_name"])
        false
      )
      jQuery.unique(names)
    )

    @scrub_csv =(e) ->
      $.trim(e.replace(/"/g,'""'))

    @pageLoadingChange = ko.computed =>
      #if the value changes from from true to false
      #the page should be done loading.
      if !@pageLoading()
        @setIDs()
        @reset()

  getHtml: (vendor_id, caller)=>
    url = @baseVenderUrl.replace("ACCOUNT_ID_SUB", @accountID).replace("CHARACTER_ID_SUB", @characterID()).replace("ACCOUNT_TYPE", @accountType).replace("VENDOR_ID", vendor_id)
    console.log(url)
    $.ajax({
      url: url, type: "GET",
      beforeSend: (xhr) ->
        #setup headers
        #Accept Might not be needed. I noticed this was used in the bungie requests
        xhr.setRequestHeader('Accept', "application/json, text/javascript, */*; q=0.01")
        #This are mostly auth headers. API token and other needed values.
        for key,value of bungieNetPlatform.getHeaders()
          xhr.setRequestHeader(key, value)
    }).error( (self, stat, message) =>
    ).done( (html) =>
      caller(html, vendor_id)
    )

  group_by: (array, key) ->
    items = {}
    for item in array
      if item[key]
        (items[item[key]] or= []).push item
    items

  reset: ->
    @selling([])
    @have([])
    @error(false)
    try
      @processItems()
    catch error
      @error("There was a problem loading the site: #{error}")

  processItems: =>
    #outfitter, shipwright
    for vendor in [134701236,459708109, 3658200622, 2668878854]
      @getHtml(vendor, (html,v) =>
        j = $(html)
        for item in $.makeArray(j.find(".destiny-icon-item"))

          item_object = {}
          item_object["vendor_name"] = @vendor_names[v]
          item_object["title"] =@scrub_csv($(item).find(".standardTitle").text())
          item_object["type"] =@scrub_csv($(item).find(".standardDesc  :first-child").text())
          item_object["requirements"] = @scrub_csv($(item).find(".requirements").text())
          item_object["tier"] = @scrub_csv($(item).find(".itemSubtitle .tierTypeName").text())
          item_object["failure"] = @scrub_csv($(item).find(".vendorFailureReasons").text())
          if item_object["type"]=="Vehicle" || item_object["type"]=="Ship" || item_object["type"]=="Emblem" ||item_object["type"]=="Armor Shader"
            @selling.push(item_object)
      )
    #shader, ships, sparrows, emblems
    for vendor in [2420628997, 2244880194, 44395194, 3301500998]
      @getHtml(vendor, (html,v) =>
        j = $(html)
        for item in $.makeArray(j.find(".destiny-icon-item"))
          item_object = {}
          item_object["vendor_name"] = @vendor_names[v]
          item_object["title"] =@scrub_csv($(item).find(".standardTitle").text())
          item_object["type"] =@scrub_csv($(item).find(".standardDesc  :first-child").text())
          item_object["requirements"] = @scrub_csv($(item).find(".requirements").text())
          item_object["tier"] = @scrub_csv($(item).find(".itemSubtitle .tierTypeName").text())
          item_object["failure"] = @scrub_csv($(item).find(".vendorFailureReasons").text())
          if item_object["type"]=="Vehicle" || item_object["type"]=="Ship" || item_object["type"]=="Emblem" ||item_object["type"]=="Armor Shader"
            @have.push(item_object)
      )

  setIDs: ->
    #simple regex.
    matches = window.location.pathname.match(/(.+)(\d+)\/(\d+)\/(\d+)/)
    @accountType = matches[2]
    @accountID = matches[3]
    @characterID(matches[4])

window.upgrader = new Shopper

unless $('.upgrader')[0]
  colors =
    primary: '#21252B'
    secondary: '#2D3137'
    tertiary: '#393F45'

  $(".nav_top").append("
  <style>
    .upgrader {
      width: 300px;
      min-height: 10px;
      max-height: 550px;
      clear: left;
      background-color: #{colors.primary};
      color: #fff;
      padding: 0 .5em;
      overflow-x: auto;
      border-bottom: #{colors.primary} solid 1px;
      border-radius: 0 0 0 5px;
      float: right;
      height: auto !important;
    }
    .upgrader .header {
      height: 20px;
      padding: .5em 0;
    }
    .upgrader .header span {
      cursor: pointer;
      float: left;
    }
    .upgrader .header label {
      float: right;
    }
    .upgrader .item {
      background: #{colors.secondary};
      border-radius: 5px;
      margin:.5em 0;
    }
    .upgrader .item-header {
      padding: .25em .5em;
      display: inline-block;
    }
    .upgrader .item ul {
      background: #{colors.tertiary};
      border-radius: 0 0 5px 5px;
      padding:.25em .5em;
    }
  </style>
  <li class='upgrader'>
    <div class='header'>
      <!-- ko ifnot: error -->
        <span onclick='$(\"#upgrader-data\").toggle();return false;'>
          Shopping list
        </span>
      <!-- /ko -->
      <!-- ko if: error -->
        <span data-bind='text: error'></span>
      <!-- /ko -->
    </div>
      <span id='upgrader-data' data-bind='foreach: buy_types'>
       <!-- ko if: $parent.buy_list()[$data] -->
        <span data-bind='text: $data' class='item-header'/>
        <ul data-bind='foreach: $parent.buy_list()[$data]'>
          <li data-bind=\"text: type +': '+title\" class='item'></li>
        </ul>
        <!-- /ko -->
    </span>
  </li>")
  #bind my object to my new dom element

  ko.applyBindings(window.upgrader, $('.upgrader')[0])

