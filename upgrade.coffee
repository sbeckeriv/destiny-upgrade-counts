#knockout object to hold all the different data
class Item
  constructor: (data)->
    ko.mapping.fromJS(data, {}, @)
  displayName: ->
    name = "#{@data.itemName()}: #{@bucket.bucketName()}"
    name += " Vault" if @vault()
    name
  check_vault: ->
    !@vault()

  csv: (stats_header, material_names)->
    item_csv = [@data.itemName(), @data.itemTypeName(), @data.tierTypeName(), @data.qualityLevel() ]
    stat_csv = []
    for stat in stats_header
      found_stat = (instace_stat for instace_stat in  @instance.stats() when instace_stat.statHash() == stat)[0]
      if found_stat
        stat_csv[stats_header.indexOf(stat)] = found_stat.value()
      else
        stat_csv[stats_header.indexOf(stat)] = ""
    perk_string = ""
    for perk in @instance.perks()
      perk_string += "#{@json.Response.definitions.perks[perk.perkHash()].displayName()}\n"
    mat_data = []
    for name in material_names
      count = 0
      if @material_names[name]
        count = @material_names[name]()
      mat_data.push(count)
    string = item_csv.concat(stat_csv, ["\"#{perk_string}\""], mat_data).join()
    string

#knockout object to hold the totals to update display
class Totals
  constructor: ->
    @names = ko.observableArray([])
    # group names and totals. I could not figure out how to loop over names in the
    # knockout html and access the data still
    @list = ko.computed( =>
      [name, @[name]()] for name in @names()
    )
  count: (name) =>
    if @[name]
      @[name]()
    else
      0
  add: (name,count) =>
    # if we already have it add it. If not create observable. Add list to name as a key.
    if @[name]
      @[name](@[name]()+count)
    else
      @[name] = ko.observable(count)
      @names.push(name)

class Upgrader
  baseInventoryUrl: window.location.protocol+"//www.bungie.net/Platform/Destiny/1/Account/ACCOUNT_ID_SUB/Character/CHARACTER_ID_SUB/Inventory/IIID_SUB/?lc=en&fmt=true&lcin=true&definitions=true"
  vaultInventoryUrl: window.location.protocol+"//www.bungie.net/Platform/Destiny/1/MyAccount/Character/CHARACTER_ID_SUB/Vendor/VENDOR_ID/?lc=en&fmt=true&lcin=true&definitions=true"
  constructor: ->
    @accountID = null
    @characterID = null
    @items = ko.observableArray()
    @totals = new Totals
    @vaultTotals = new Totals
    @ownedTotals = new Totals
    @setIDs()
    @vaultLoaded = ko.observable(false) # can be computed if any items have vault
    @displayVault = ko.observable(false)
    @error = ko.observable(false)
    try
      @processItems()
      @venderTimeout = setInterval(=>
        @processVault()
      , 600)
    catch error
      @error("There was a problem loading the site: #{error}")

  total_object: ->
    if @displayVault()
      @vaultTotals
    else
      @totals

  itemsCSV: ->
    header = ["Name", "Type", "Tier", "Quality Level"]
    stats_header = []
    for id, data of DEFS.stats
      stats_header.push(parseInt(id,10))
      header.push(data.statName)
    mat_names = @total_object().names()
    header.push("Perks")
    header = header.concat(mat_names)
    csv = [header.join()]
    for item in @items()
      if ["BUCKET_SPECIAL_WEAPON","BUCKET_HEAVY_WEAPON","BUCKET_PRIMARY_WEAPON"].indexOf(item.bucket.bucketIdentifier())>=0
        csv.push(item.csv(stats_header, mat_names))
    csv

  processVault: ->
    vendor_id = null
    if DEFS.vendorDetails
      for id, obj of DEFS.vendorDetails
        vendor_id = id
    if vendor_id
      clearInterval(@venderTimeout)
      @vaultLoaded(true)
      url = @vaultInventoryUrl.replace("CHARACTER_ID_SUB", @characterID).replace("VENDOR_ID", vendor_id)
      $.ajax({
        url: url, type: "GET",
        beforeSend: (xhr) ->
          #setup headers
          #Accept Might not be needed. I noticed this was used in the bungie requests
          xhr.setRequestHeader('Accept', "application/json, text/javascript, */*; q=0.01")
          #This are mostly auth headers. API token and other needed values.
          for key,value of bungieNetPlatform.getHeaders()
            xhr.setRequestHeader(key, value)
      }).done (item_json) =>
        for bucket in item_json["Response"]["data"]["inventoryBuckets"]
          for item in bucket.items
            datas = item_json["Response"]["definitions"]["items"][item.itemHash]
            if @ownedTotals[datas.itemName]
              @ownedTotals.add(datas.itemName, item.stackSize)

            @addItem(item.itemInstanceId, {"vault": true, "data": datas, "instance":item, "bucket": item_json["Response"]["definitions"]["buckets"][bucket.bucketHash]})
    else

  processItems: ->
    # use bungie js model to key the values. Just a double loop of arrays
    for item in tempModel.inventory.buckets.Equippable
      for object in item.items
        data = DEFS["items"][object.itemHash]
        @addItem(object.itemInstanceId, {"vault": false, "instance": object, "data": data, "bucket": DEFS['buckets'][data.bucketTypeHash]})
    #equipped only
    for bucket in tempModel.inventory.buckets.Item
      if DEFS.buckets[bucket.bucketHash].bucketIdentifier == "BUCKET_MATERIALS"
        for item in bucket.items
          name = DEFS["items"][item.itemHash].itemName
          @ownedTotals.add(name, item.stackSize)

  setIDs: ->
    #simple regex.
    matches = window.location.pathname.match(/(.+)\/(\d+)\/(\d+)/)
    @accountID = matches[2]
    @characterID = matches[3]
  #turn [{x: 5, y:6}, {x:5, y:7}}] in to {5: [{x: 5, y:6}, {x:5, y:7}}}
  #usefully for grouping items over different arrays
  group_by: (array, key) ->
    items = {}
    for item in array
      (items[item[key]] or= []).push item
    items

  addItem: (iiid, base_object) =>
    url = @baseInventoryUrl.replace("ACCOUNT_ID_SUB", @accountID).replace("CHARACTER_ID_SUB", @characterID).replace("IIID_SUB", iiid)

    $.ajax({
      url: url, type: "GET",
      beforeSend: (xhr) ->
        #setup headers
        #Accept Might not be needed. I noticed this was used in the bungie requests
        xhr.setRequestHeader('Accept', "application/json, text/javascript, */*; q=0.01")
        #This are mostly auth headers. API token and other needed values.
        for key,value of bungieNetPlatform.getHeaders()
          xhr.setRequestHeader(key, value)
    }).done (item_json) =>
      material_list = []
      for talentNodes in item_json["Response"]["data"]["talentNodes"]
        for material in talentNodes.materialsToUpgrade
          #name and other details is stored under definitions. Then the instance for you is under data.
          #This is so you always have the details for what you are displaying. If parts is in the data list
          #50 times you only see general details for parts once instead of 50. Helps on space?
          material["name"] = item_json["Response"]["definitions"]["items"][material.itemHash]["itemName"]
          material_list.push(material)
      #should look like {"Helium Filaments": [...], "Ascendant Energy": [..]}
      materials = @group_by(material_list, "name")
      #storing data to use for later.
      base_object["json"] = item_json
      base_object["material"] = materials
      clean_list = {}
      #count for each material
      #store the over all total too. We could count this on the way out as well.
      for name, ms of materials
        total = 0
        total = total+ m.count for m in ms
        @vaultTotals.add(name,total)
        @totals.add(name,total) unless base_object["vault"]
        clean_list[name] = total
      clean_array = ({name: name, total: total} for name, total of clean_list)
      base_object["material_names"] = clean_list
      base_object["material_array"] = clean_array
      @items.push(new Item(base_object))

window.upgrader = new Upgrader

unless $('.upgrader')[0]
  $(".nav_top").append("<li class='upgrader' style='width:300px;clear:left;background-color:white;min-height:10px;max-height:550px;overflow-x:auto'>
    <div style='height:20px'>
      <!-- ko ifnot: error -->
        <a href='#' onclick='$(\"#upgrader-data\").toggle();return false;'>UPGRADES</a>
      <!-- /ko -->
      <!-- ko if: error -->
        <span data-bind='text: error'></span>
      <!-- /ko -->
    </div>
    <span id='upgrader-data' data-bind='ifnot: error'>
      <label><input type='checkbox' data-bind='checked: displayVault, attr: {disabled: !vaultLoaded()}' />
      <!-- ko ifnot: vaultLoaded()-->
        Click Gear for Vault
      <!-- /ko -->
      <!-- ko if: vaultLoaded()-->
        Include Vault
      <!-- /ko -->
      </label>
      <ul class='totals' data-bind='foreach: total_object().list()'>
        <li data-bind=\"text: $data[0]+': '+$data[1]+'('+$parent.ownedTotals.count($data[0])+')'\"></li>
      </ul>
      <ul class='totals' data-bind='foreach: items'>
        <!-- ko if:(material_array()[0] && ($parent.displayVault() || !vault())) -->
          <li class='item' style='border-bottom: solid 1px'>
            <span data-bind='text: displayName()'></span>
            <ul data-bind='foreach: material_array()'>
              <li style='color:#B5B7A4;background-color:#4D5F5F' data-bind=\"text: name()+': '+total()\"></li>
            </ul>
          </li>
        <!-- /ko -->
      </ul>

    </span>

  </li>")
  #bind my object to my new dom element
  ko.applyBindings(window.upgrader, $('.upgrader')[0])
