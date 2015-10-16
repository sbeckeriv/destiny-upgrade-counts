// Generated by CoffeeScript 1.8.0
(function() {
  var Shopper, colors,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Shopper = (function() {
    Shopper.prototype.baseVenderUrl = window.location.protocol + "//www.bungie.net/en/Vendors/ACCOUNT_TYPE/ACCOUNT_ID_SUB/CHARACTER_ID_SUB?vendor=VENDOR_ID&category=2";

    function Shopper() {
      this.processItems = __bind(this.processItems, this);
      this.getHtml = __bind(this.getHtml, this);
      this.accountID = null;
      this.characterID = ko.observable(null);
      this.accountType = null;
      this.pageLoading = ko.observable(false);
      this.have = ko.observableArray();
      this.selling = ko.observableArray();
      this.error = ko.observable(false);
      this.vendor_names = {
        134701236: "Outfitter",
        459708109: "Shipwright",
        2420628997: "Shader",
        2244880194: "Ship",
        44395194: "Sparrow",
        3301500998: "Emblem",
        2668878854: "Vanguard Quartermaster",
        3658200622: "Crucible Quartermaster",
        1998812735: "Variks (Reef)",
        1410745145: "Petra (Reef)"
      };
      this.setIDs();
      setInterval((function(_this) {
        return function() {
          var loading;
          loading = bnet._pageController.isLoadingPage;
          if (loading !== _this.pageLoading()) {
            return _this.pageLoading(loading);
          }
        };
      })(this), 500);
      this.buy_list = ko.computed((function(_this) {
        return function() {
          var found, have_item, item, list, _i, _j, _len, _len1, _ref, _ref1;
          list = [];
          _ref = _this.selling();
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            item = _ref[_i];
            found = false;
            _ref1 = _this.have();
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              have_item = _ref1[_j];
              if (have_item["title"] === item["title"] && (have_item["requirements"].match("1/1") || have_item["requirements"].match("2/2") || have_item["requirements"] === "")) {
                found = true;
              }
            }
            if (!found) {
              list.push(item);
            }
          }
          return _this.group_by(list, "vendor_name");
        };
      })(this));
      this.buy_types = ko.computed((function(_this) {
        return function() {
          var list, names;
          names = [];
          list = _this.selling().filter(function(item, index) {
            names.push(item["vendor_name"]);
            return false;
          });
          return jQuery.unique(names);
        };
      })(this));
      this.scrub_csv = function(e) {
        return $.trim(e.replace(/"/g, '""'));
      };
      this.pageLoadingChange = ko.computed((function(_this) {
        return function() {
          if (!_this.pageLoading()) {
            _this.setIDs();
            return _this.reset();
          }
        };
      })(this));
    }

    Shopper.prototype.getHtml = function(vendor_id, caller) {
      var url;
      url = this.baseVenderUrl.replace("ACCOUNT_ID_SUB", this.accountID).replace("CHARACTER_ID_SUB", this.characterID()).replace("ACCOUNT_TYPE", this.accountType).replace("VENDOR_ID", vendor_id);
      console.log(url);
      return $.ajax({
        url: url,
        type: "GET",
        beforeSend: function(xhr) {
          var key, value, _ref, _results;
          xhr.setRequestHeader('Accept', "application/json, text/javascript, */*; q=0.01");
          _ref = bungieNetPlatform.getHeaders();
          _results = [];
          for (key in _ref) {
            value = _ref[key];
            _results.push(xhr.setRequestHeader(key, value));
          }
          return _results;
        }
      }).error((function(_this) {
        return function(self, stat, message) {};
      })(this)).done((function(_this) {
        return function(html) {
          return caller(html, vendor_id);
        };
      })(this));
    };

    Shopper.prototype.group_by = function(array, key) {
      var item, items, _i, _len, _name;
      items = {};
      for (_i = 0, _len = array.length; _i < _len; _i++) {
        item = array[_i];
        if (item[key]) {
          (items[_name = item[key]] || (items[_name] = [])).push(item);
        }
      }
      return items;
    };

    Shopper.prototype.reset = function() {
      var error;
      this.selling([]);
      this.have([]);
      this.error(false);
      try {
        return this.processItems();
      } catch (_error) {
        error = _error;
        return this.error("There was a problem loading the site: " + error);
      }
    };

    Shopper.prototype.processItems = function() {
      var vendor, _i, _j, _len, _len1, _ref, _ref1, _results;
      _ref = [134701236, 459708109, 3658200622, 2668878854];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        vendor = _ref[_i];
        this.getHtml(vendor, (function(_this) {
          return function(html, v) {
            var item, item_object, j, _j, _len1, _ref1, _results;
            j = $(html);
            _ref1 = $.makeArray(j.find(".destiny-icon-item"));
            _results = [];
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              item = _ref1[_j];
              item_object = {};
              item_object["vendor_name"] = _this.vendor_names[v];
              item_object["title"] = _this.scrub_csv($(item).find(".standardTitle").text());
              item_object["type"] = _this.scrub_csv($(item).find(".standardDesc  :first-child").text());
              item_object["requirements"] = _this.scrub_csv($(item).find(".requirements").text());
              item_object["tier"] = _this.scrub_csv($(item).find(".itemSubtitle .tierTypeName").text());
              item_object["failure"] = _this.scrub_csv($(item).find(".vendorFailureReasons").text());
              if (item_object["type"] === "Vehicle" || item_object["type"] === "Ship" || item_object["type"] === "Emblem" || item_object["type"] === "Armor Shader") {
                _results.push(_this.selling.push(item_object));
              } else {
                _results.push(void 0);
              }
            }
            return _results;
          };
        })(this));
      }
      _ref1 = [2420628997, 2244880194, 44395194, 3301500998];
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        vendor = _ref1[_j];
        _results.push(this.getHtml(vendor, (function(_this) {
          return function(html, v) {
            var item, item_object, j, _k, _len2, _ref2, _results1;
            j = $(html);
            _ref2 = $.makeArray(j.find(".destiny-icon-item"));
            _results1 = [];
            for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
              item = _ref2[_k];
              item_object = {};
              item_object["vendor_name"] = _this.vendor_names[v];
              item_object["title"] = _this.scrub_csv($(item).find(".standardTitle").text());
              item_object["type"] = _this.scrub_csv($(item).find(".standardDesc  :first-child").text());
              item_object["requirements"] = _this.scrub_csv($(item).find(".requirements").text());
              item_object["tier"] = _this.scrub_csv($(item).find(".itemSubtitle .tierTypeName").text());
              item_object["failure"] = _this.scrub_csv($(item).find(".vendorFailureReasons").text());
              if (item_object["type"] === "Vehicle" || item_object["type"] === "Ship" || item_object["type"] === "Emblem" || item_object["type"] === "Armor Shader") {
                _results1.push(_this.have.push(item_object));
              } else {
                _results1.push(void 0);
              }
            }
            return _results1;
          };
        })(this)));
      }
      return _results;
    };

    Shopper.prototype.setIDs = function() {
      var matches;
      matches = window.location.pathname.match(/(.+)(\d+)\/(\d+)\/(\d+)/);
      this.accountType = matches[2];
      this.accountID = matches[3];
      return this.characterID(matches[4]);
    };

    return Shopper;

  })();

  window.upgrader = new Shopper;

  if (!$('.upgrader')[0]) {
    colors = {
      primary: '#21252B',
      secondary: '#2D3137',
      tertiary: '#393F45'
    };
    $(".nav_top").append("<style> .upgrader { width: 300px; min-height: 10px; max-height: 550px; clear: left; background-color: " + colors.primary + "; color: #fff; padding: 0 .5em; overflow-x: auto; border-bottom: " + colors.primary + " solid 1px; border-radius: 0 0 0 5px; float: right; height: auto !important; } .upgrader .header { height: 20px; padding: .5em 0; } .upgrader .header span { cursor: pointer; float: left; } .upgrader .header label { float: right; } .upgrader .item { background: " + colors.secondary + "; border-radius: 5px; margin:.5em 0; } .upgrader .item-header { padding: .25em .5em; display: inline-block; } .upgrader .item ul { background: " + colors.tertiary + "; border-radius: 0 0 5px 5px; padding:.25em .5em; } </style> <li class='upgrader'> <div class='header'> <!-- ko ifnot: error --> <span onclick='$(\"#upgrader-data\").toggle();return false;'> Shopping list </span> <!-- /ko --> <!-- ko if: error --> <span data-bind='text: error'></span> <!-- /ko --> </div> <span id='upgrader-data' data-bind='foreach: buy_types'> <!-- ko if: $parent.buy_list()[$data] --> <span data-bind='text: $data' class='item-header'/> <ul data-bind='foreach: $parent.buy_list()[$data]'> <li data-bind=\"text: type +': '+title\" class='item'></li> </ul> <!-- /ko --> </span> </li>");
    ko.applyBindings(window.upgrader, $('.upgrader')[0]);
  }

}).call(this);
