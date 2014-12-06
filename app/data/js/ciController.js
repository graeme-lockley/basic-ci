var myApp = angular.module("basicCI", []);

myApp.controller("CICtrl", function ($scope, $http) {
    $http
        .get("/api/projects")
        .success(function (response) {
            $scope.projects = response;
        });
});
