<%@ page 
    language="java"
    contentType="text/html; charset=UTF-8"
    trimDirectiveWhitespaces="true"
    pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/fragments/taglibs.jsp" %>

<div data-ng-controller="TestRunsListCtrl">
	<div class="row">
         <div class="col-lg-12">
         	<h2><i class="fa fa-play-circle fa-fw"></i> Test runs</h2>
         </div>
    </div>
	<div class="row">
		<div class="col-lg-12">
            <div class="row">
            	<div class="col-lg-3">
            		Enable real-time events <input type="checkbox" data-ng-model="showRealTimeEvents" />
            	</div>
            	<div class="col-lg-9" align="right">
            		<span>Found: {{totalResults}}&nbsp;</span>
					<a href="" data-ng-click="resetSearchCriteria(); loadTestRuns(1);" class="clear-form danger">Reset&nbsp;<i class="fa fa-times-circle"></i>&nbsp;</a>
					<a href="" data-ng-click="loadTestRuns(1)">Search&nbsp;<i class="fa fa-arrow-circle-right"></i></a>
				</div>
            </div>
            <div class="row results_header">
            	<div class="col-lg-4"><input type="text" class="form-control" placeholder="Test suite" data-ng-model="testRunSearchCriteria.testSuite"></div>
            	<div class="col-lg-4"><input type="text" class="form-control" placeholder="Execution URL" data-ng-model="testRunSearchCriteria.executionURL"></div>
            	<div class="col-lg-1"><input type="text" class="form-control" placeholder="Env" data-ng-model="testRunSearchCriteria.environment"></div>
            	<div class="col-lg-1">
            		<!-- input type="text" class="form-control" placeholder="Platform" data-ng-model="testRunSearchCriteria.platform" -->
            		<select class="form-control icon-menu" data-ng-model="testRunSearchCriteria.platform" style="padding: 0;">
            			<option value="" disabled selected>Platform</option>
            			<option value="Android">Android</option>
            			<option value="iOS">iOS</option>
            			<option value="chrome">chrome</option>
            			<option value="firefox">firefox</option>
            			<option value="safari">safari</option>
            			<option value="ie">ie</option>
            		</select>
            	</div>
            	<div class="col-lg-2"><input type="date" class="form-control" placeholder="Date" data-ng-model="testRunSearchCriteria.date"></div>
            </div>
            <div class="run_result row" align="center" data-ng-show="totalResults == 0">
            	<div class="col-lg-12">No results</div>
            </div>
			<div class="run_result row progressbar_container" data-ng-class="'result_' + testRun.status" data-ng-repeat="(id, testRun) in testRuns | orderObjectBy:'modifiedAt':true" <sec:authorize access="hasAnyRole('ROLE_ADMIN')">context-menu="adminMenuOptions"</sec:authorize> <sec:authorize access="hasAnyRole('ROLE_USER')">context-menu="userMenuOptions"</sec:authorize>>
				<timer countdown="testRun.countdown" interval="1000" data-ng-if="testRun.status == 'IN_PROGRESS' && testRun.countdown">
					<div class="progressbar_bg" style="width:{{progressBar}}%"></div>
				</timer>
				<div class="col-lg-4">
					<!-- input type="checkbox"
							data-ng-model="isChecked"
							data-ng-true-value="true"
							data-ng-false-value="false"
							data-ng-change="selectTestRun(testRun.id, isChecked)"
							value="{{testRun.id}}" 
							name="{{testRun.id}}"
							data-ng-show="testRun.status != 'IN_PROGRESS' && testRunId == null" onclick="event.cancelBubble=true;"/ -->
					<img data-ng-if="testRun.status == 'IN_PROGRESS'" src="<c:url value="/resources/img/pending.gif" />" class="pending"/>
				  	<b>{{testRun.testSuite.name}}</b>
				</div>
				<div class="col-lg-4">
					<a href="{{testRun.jenkinsURL}}" target="_blank">{{UtilService.truncate(testRun.jenkinsURL, 50)}}</a>
				</div>
				<div class="col-lg-1">
					<span class="badge">{{getArgValue(testRun.configXML, 'env')}}</span>
				</div>
				<div  class="col-lg-1" align="center">
					<span class="platform-icon {{getArgValue(testRun.configXML, 'browser')}} {{getArgValue(testRun.configXML, 'mobile_platform_name')}}"></span>
				</div>
				<div  class="col-lg-2" style="padding-right: 3px;">
					<div>
						<span class="time">{{testRun.modifiedAt | date:'MM/dd HH:mm'}}</span>
						&nbsp;
						<span class="label arrowed arrowed-in-right label-success-border" data-ng-class="{'label-success-empty': testRun.passed == 0, 'label-success': testRun.passed > 0}">{{testRun.passed}}</span>
						<span class="label arrowed arrowed-in-right label-danger-border" data-ng-class="{'label-danger-empty': testRun.failed == 0, 'label-danger': testRun.failed > 0}">{{testRun.failed}}</span>
						<span class="label arrowed arrowed-in-right label-warning-border" data-ng-class="{'label-warning-empty': testRun.skipped == 0, 'label-warning': testRun.skipped > 0}">{{testRun.skipped}}</span>
						&nbsp;
						<i data-ng-class="{'fa fa-lg fa-sort-desc': testRun.showDetails == false, 'fa fa-lg fa-sort-asc': testRun.showDetails == true}" aria-hidden="true" data-ng-click="showDetails(testRun.id)"  class="float_right pointer"></i>
					</div>
				</div>
				<div class="col-lg-12" data-ng-if="testRun.showDetails == true" style="margin-top: 10px;">
                    <div class="row test_result" data-ng-class="test.status" data-ng-repeat="test in testRun.tests | orderBy:'id':false">
                    	<div class="col-lg-10">
                    		<div class="clearfix">
                    			<img data-ng-if="test.status == 'IN_PROGRESS'" src="<c:url value="/resources/img/pending.gif" />" class="pending"/> {{test.name}} 
                    			<a href="" class="float_right clearfix label-success-empty" data-ng-if="test.status == 'FAILED' || test.status == 'SKIPPED'" data-ng-click="markTestAsPassed(test.id)">Mark as passed</a>
                    			<span class="float_right" data-ng-if="test.status == 'FAILED' && test.knownIssue == false" style="margin: 0 5px;">|</span>
                    			<a href="" class="float_right clearfix label-warning-empty" data-ng-if="test.status == 'FAILED' && test.knownIssue == false" data-ng-click="openKnownIssueModal(test)">Mark as known issue</a>
                    		</div>
                            <div class="result_error" data-ng-if="test.message && test.status == 'FAILED'">
                            	<show-more text="test.message" limit="100"></show-more>
                            </div>
                    	</div>
                    	<div class="col-lg-1 center" style="padding: 0;">
                    		<span data-ng-repeat="issue in test.workItems">
                    			<a href="{{jiraURL + '/' + issue.jiraId}}" target="_blank" data-ng-if="issue.type == 'TASK'" class="badge ng-binding" style="background-color: #337ab7;">{{issue.jiraId}}</a>
                    			<a href="{{jiraURL + '/' + issue.jiraId}}" target="_blank" data-ng-if="issue.type == 'BUG' && test.status == 'FAILED'" class="badge ng-binding" style="background-color: #d9534f;" alt="{{issue.description}}" title="{{issue.description}}">{{issue.jiraId}}</a>
                    		</span>
                    	</div>
                    	<div class="col-lg-1 center" style="padding: 0;">
                    		<div data-ng-if="test.status != STARTED">
                            	<a data-ng-if="test.logURL  && testRun.status != 'IN_PROGRESS'" href="{{test.logURL}}" target="blank">Log</a> <span data-ng-if="test.demoURL && testRun.status != 'IN_PROGRESS'">| <a href="{{test.demoURL}}" target="blank">Demo</a></span>
                       		</div>
                    	</div>
	                 </div>
				</div>
			</div>
			<div style="padding: 5px 15px;">
				<a href="#/tests/runs/{{compareQueryString}}/compare" class="float_left" data-ng-show="testRunsToCompare.length > 1" target="blank">Compare</a>
				<paging class="float_right"
					  page="testRunSearchCriteria.page" 
					  page-size="testRunSearchCriteria.pageSize" 
					  total="totalResults"
					  show-prev-next="true"
					  show-first-last="true"
					  paging-action="loadTestRuns(page)" >
				</paging>
			</div>
			<br/>
		</div>
	</div>
</div>

              