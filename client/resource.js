// http://kirkbushell.me/angular-js-using-ng-resource-in-a-more-restful-manner
var module = angular.module('RESTfulResource', ['ngResource']);

module.factory('resource', function ($resource) {
  return function (url, params, methods) {
    var defaults = {
      update: {method: 'PUT', isArray: false},
      create: {method: 'POST'}
    };

    methods = angular.extend(defaults, methods);

    var resource = $resource(url, params, methods);

    resource.prototype.$save = function (callback) {
      if (this.id) {
        // For some reason this is being submitted to the server.
        delete this.$resolved;
        delete this.createdAt;
        return this.$update({id: this.id}, callback);
      } else {
        return this.$create(callback);
      };
    };

    return resource;
  };
});
