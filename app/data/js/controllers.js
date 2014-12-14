var ciControllers = angular.module("ciControllers", []);

ciControllers.controller("ProjectsCtrl", function ($scope, $http) {
    var promise = $http.get("/api/projects");

    promise.success(function (response) {
        $scope.projects = response;
    });
});

ciControllers.controller("ProjectDetailCtrl", function ($scope, $http, $routeParams) {
    $scope.projectID = $routeParams.projectID;

    var promise = $http.get("/api/projects/" + $scope.projectID + "/pipelines");
    promise.success(function (response) {
        $scope.project = response;
    });

    $scope.taskMarkup = function (pipelineStatus, pipelineTask, step) {
        if (pipelineStatus == 'ready') {
            return 'bg-active';
        } else if (pipelineStatus == 'complete') {
            return 'bg-success';
        } else if (pipelineTask == step.name) {
            if (pipelineStatus == 'running') {
                return 'bg-warning';
            } else {
                return 'bg-danger';
            }
        } else if (step.name < pipelineTask) {
            return 'bg-success';
        } else {
            console.log(pipelineStatus, pipelineTask, step);
            return 'bg-active';
        }
    };
});
