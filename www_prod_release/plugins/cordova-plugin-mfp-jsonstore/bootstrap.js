cordova.define("cordova-plugin-mfp-jsonstore.jsonstore", function(require, exports, module) {
/*
   Licensed Materials - Property of IBM

   (C) Copyright 2015, 2016 IBM Corp.

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

// {platform}/www/plugins/cordova-plugin-mfp-jsonstore/worklight
var WORKLIGHT_DIR = 'plugins/cordova-plugin-mfp-jsonstore/worklight';

//{platform}/www/plugins/cordova-plugin-mfp-jsonstore/worklight/jsonstore.js
var JSONSTORE_PATH = WORKLIGHT_DIR + '/jsonstore.js';

document.addEventListener('mfpjsloaded', loadJSONStore, false);
function loadJSONStore(){

	if(typeof WL !== 'undefined' && WL._JSONStoreImpl){
		//console.log('Developer is injecting scripts manually');
		/*
		<script src="worklight/static_app_props.js"></script>
		<script src="cordova.js"></script>
		<script src="worklight/wljq.js"></script>
		<script src="worklight/worklight.js"></script>
		<script src="worklight/checksum.js"></script>
		<script src="worklight/jsonstore.js"></script>
		*/
		mfpjsonstoreready();
	} else {
		//console.log('Inject MFP JSONStore Scripts dynamically');
		loadJSONStoreScript();
	}

	function mfpjsonstoreready(){
		var wlevent;

		//console.log("bootstrap.js dispatching mfpjsonjsloaded event");

		try {
			wlevent = new Event('mfpjsonjsloaded');
		} catch (err) {
			if (err instanceof TypeError) {
				// Trying to use old events
				wlevent = document.createEvent('Event');
				wlevent.initEvent('mfpjsonjsloaded', true, true);
			} else
				console.error(err.message);
		}

		// Dispatch the event.
		document.dispatchEvent(wlevent);
	}

	function loadJSONStoreScript(){
		//console.log("injecting script jsonstore.js");
		injectScript(findCordovaPath() + JSONSTORE_PATH, mfpjsonstoreready,
			bootError);
	}
	
	function injectScript(url, onload, onerror) {
	    var script = document.createElement("script");
	    // onload fires even when script fails loads with an error.
	    script.onload = onload;
	    // onerror fires for malformed URLs.
	    script.onerror = onerror;
	    script.src = url;
	    document.head.appendChild(script);
	}

	function bootError(errMsg) {
		throw errMsg;
	}
}

function findCordovaPath() {
    var path = null;
    var scripts = document.getElementsByTagName('script');
    var term = '/cordova.js';
    for (var n = scripts.length-1; n>-1; n--) {
        var src = scripts[n].src.replace(/\?.*$/, ''); // Strip any query param (CB-6007).
        if (src.indexOf(term) === (src.length - term.length)) {
            path = src.substring(0, src.length - term.length) + '/';
            break;
        }
    }
    return path;
}

});
