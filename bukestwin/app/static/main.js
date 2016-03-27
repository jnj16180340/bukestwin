(function () {
    
    'use strict';
    
    angular.module('AnnApp', [])
    
    .controller('AnnController', ['$scope', '$log', function($scope, $log) {
        $scope.getResults = function() {
            $log.log("test");
            console.info("blah");
        };
    }
    
    ]);
    
}());
