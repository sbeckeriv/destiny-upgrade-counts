class Item
  constructor: (data)->
    ko.mapping.fromJS(data, {}, @)

class Totals
  constructor: ->
    @names = ko.observableArray([])
    @list = ko.computed( =>
      [name, @[name]()] for name in @names()
    )
  add: (name,count) =>
    if @[name]
      @[name](@[name]()+count)
    else
      @[name] = ko.observable(count)
      @names.push(name)

class Upgrader
  baseInventoryUrl: "http://www.bungie.net/Platform/Destiny/1/Account/ACCOUNT_ID_SUB/Character/CHARACTER_ID_SUB/Inventory/IIID_SUB/?lc=en&fmt=true&lcin=true&definitions=true"
  constructor: ->
    @accountID = null
    @characterID = null
    @items = ko.observable({})
    @ko_items = ko.observableArray()
    @totals = new Totals
    @setIDs()
    @processItems()

  processItems: ->
    for item in tempModel.inventory.buckets.Equippable
      for object in item.items
        @items()[object.itemHash] = {"instance": object, "data": DEFS["items"][object.itemHash]}
        @addItem(object.itemHash, object.itemInstanceId)

  setIDs: ->
    matches = window.location.pathname.match(/(.+)\/(\d+)\/(\d+)/)
    @accountID = matches[2]
    @characterID = matches[3]

  base_json: ->
    window.DEFS

  group_by: (array, key) ->
    items = {}
    for item in array
      (items[item[key]] or= []).push item
    items

  addItem: (hashid, iiid) =>
    url = @baseInventoryUrl.replace("ACCOUNT_ID_SUB", @accountID).replace("CHARACTER_ID_SUB", @characterID).replace("IIID_SUB", iiid)
    $.ajax({
      url: url, type: "GET",
      beforeSend: (xhr) ->
        xhr.setRequestHeader('Accept', "application/json, text/javascript, */*; q=0.01")
        for key,value of bungieNetPlatform.getHeaders()
          xhr.setRequestHeader(key, value)
    }).done (item_json) =>
      material_list = []
      for talentNodes in item_json["Response"]["data"]["talentNodes"]
        for material in talentNodes.materialsToUpgrade
          material["name"] = item_json["Response"]["definitions"]["items"][material.itemHash]["itemName"]
          material_list.push(material)
      materials = @group_by(material_list, "name")
      @items()[hashid]["json"] = item_json
      @items()[hashid]["material"] = materials
      clean_list = {}
      for name, ms of materials
        total = 0
        total = total+ m.count for m in ms
        @totals.add(name,total)
        clean_list[name] = total
      clean_array = ({name: name, total: total} for name, total of clean_list)
      @items()[hashid]["material_names"] = clean_list
      @items()[hashid]["material_array"] = clean_array
      @ko_items.push(new Item(@items()[hashid]))

upgrader = new Upgrader

$(".nav_top").append("<li class='upgrader level_one mail icons' style='width:300px;clear:left;background-color:white;min-height:10px;max-height:550px;overflow-x:auto'><div style='height:20px'><a href='#' onclick='$(\"#upgrader-data\").toggle();return false;'>UPGRADES</a></div><span id='upgrader-data'><ul class='totals' data-bind='foreach: totals.list()'> <li data-bind=\"text: $data[0]+': '+$data[1]\"></li> </ul> <ul class='totals' data-bind='foreach: ko_items'> <li class='item' style='border-bottom: solid 1px'> <span data-bind='text: data.itemName()'></span> <ul data-bind='foreach: material_array()'> <li style='color:#B5B7A4;background-color:#4D5F5F' data-bind=\"text: name()+': '+total()\"></li> </ul> </li> </ul></span> </li>")
ko.applyBindings(upgrader, $('.upgrader')[0])

