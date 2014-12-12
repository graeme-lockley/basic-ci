var ciControllers = angular.module("ciControllers", []);

ciControllers.controller("ProjectsCtrl", function ($scope, $http) {
    var promise = $http.get("/api/projects");

    promise.success(function (response) {
        $scope.projects = response;
    });
});

ciControllers.controller("ProjectDetailCtrl", function($scope, $http, $routeParams) {
   $scope.projectID = $routeParams.projectID;
});
