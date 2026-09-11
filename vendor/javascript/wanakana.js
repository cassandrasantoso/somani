// wanakana@5.3.1 downloaded from https://ga.jspm.io/npm:wanakana@5.3.1/esm/index.js

/**
 * Returns detailed type as string (instead of just 'object' for arrays etc)
 * @private
 * @param {any} value js value
 * @returns {String} type of value
 * @example
 * typeOf({}); // 'object'
 * typeOf([]); // 'array'
 * typeOf(function() {}); // 'function'
 * typeOf(/a/); // 'regexp'
 * typeOf(new Date()); // 'date'
 * typeOf(null); // 'null'
 * typeOf(undefined); // 'undefined'
 * typeOf('a'); // 'string'
 * typeOf(1); // 'number'
 * typeOf(true); // 'boolean'
 * typeOf(new Map()); // 'map'
 * typeOf(new Set()); // 'map'
 */
function typeOf(t){return t===null?"null":t!==Object(t)?typeof t:{}.toString.call(t).slice(8,-1).toLowerCase()}
/**
 * Checks if input string is empty
 * @param  {String} input text input
 * @return {Boolean} true if no input
 */function isEmpty(t){return typeOf(t)!=="string"||!t.length}
/**
 * Takes a character and a unicode range. Returns true if the char is in the range.
 * @param  {String}  char  unicode character
 * @param  {Number}  start unicode start range
 * @param  {Number}  end   unicode end range
 * @return {Boolean}
 */function isCharInRange(t="",e,n){if(isEmpty(t))return false;const a=t.charCodeAt(0);return e<=a&&a<=n}const t="5.3.1";const e={HIRAGANA:"toHiragana",KATAKANA:"toKatakana"};const n={HEPBURN:"hepburn"};
/**
 * Default config for WanaKana, user passed options will be merged with these
 * @type {DefaultOptions}
 * @name DefaultOptions
 * @property {Boolean} [useObsoleteKana=false] - Set to true to use obsolete characters, such as ゐ and ゑ.
 * @example
 * toHiragana('we', { useObsoleteKana: true })
 * // => 'ゑ'
 * @property {Boolean} [passRomaji=false] - Set to true to pass romaji when using mixed syllabaries with toKatakana() or toHiragana()
 * @example
 * toHiragana('only convert the katakana: ヒラガナ', { passRomaji: true })
 * // => "only convert the katakana: ひらがな"
 * @property {Boolean} [convertLongVowelMark=true] - Set to false to prevent conversions of 'ー' to extended vowels with toHiragana()
 * @example
 * toHiragana('ラーメン', { convertLongVowelMark: false });
 * // => 'らーめん
 * @property {Boolean} [upcaseKatakana=false] - Set to true to convert katakana to uppercase using toRomaji()
 * @example
 * toRomaji('ひらがな カタカナ', { upcaseKatakana: true })
 * // => "hiragana KATAKANA"
 * @property {Boolean | 'toHiragana' | 'toKatakana'} [IMEMode=false] - Set to true, 'toHiragana', or 'toKatakana' to handle conversion while it is being typed.
 * @property {'hepburn'} [romanization='hepburn'] - choose toRomaji() romanization map (currently only 'hepburn')
 * @property {Object.<String, String>} [customKanaMapping] - custom map will be merged with default conversion
 * @example
 * toKana('wanakana', { customKanaMapping: { na: 'に', ka: 'Bana' }) };
 * // => 'わにBanaに'
 * @property {Object.<String, String>} [customRomajiMapping] - custom map will be merged with default conversion
 * @example
 * toRomaji('つじぎり', { customRomajiMapping: { じ: 'zi', つ: 'tu', り: 'li' }) };
 * // => 'tuzigili'
 */const a={useObsoleteKana:false,passRomaji:false,convertLongVowelMark:true,upcaseKatakana:false,IMEMode:false,romanization:n.HEPBURN};const r=65;const o=90;const i=65345;const s=65370;const c=65313;const u=65338;const l=12353;const f=12438;const p=12449;const h=12540;const g=19968;const m=40879;const d=12293;const y=12540;const j=12539;const C=[65296,65305];const E=[c,u];const k=[i,s];const b=[65281,65295];const v=[65306,65311];const O=[65339,65343];const A=[65371,65376];const K=[65504,65518];const w=[12352,12447];const M=[12448,12543];const R=[65382,65439];const T=[12539,12540];const N=[65377,65381];const I=[12288,12351];const S=[19968,40959];const J=[13312,19903];const H=[w,M,N,R];const z=[I,N,T,b,v,O,A,K];const L=[...H,...z,E,k,C,S,J];const P=[0,127];const U=[[256,257],[274,275],[298,299],[332,333],[362,363]];const $=[[8216,8217],[8220,8221]];const x=[P,...U];const q=[[32,47],[58,63],[91,96],[123,126],...$];
/**
 * Tests a character. Returns true if the character is [Katakana](https://en.wikipedia.org/wiki/Katakana).
 * @param  {String} char character string to test
 * @return {Boolean}
 */function isCharJapanese(t=""){return L.some((([e,n])=>isCharInRange(t,e,n)))}
/**
 * Test if `input` only includes [Kanji](https://en.wikipedia.org/wiki/Kanji), [Kana](https://en.wikipedia.org/wiki/Kana), zenkaku numbers, and JA punctuation/symbols.”
 * @param  {String} [input=''] text
 * @param  {RegExp} [allowed] additional test allowed to pass for each char
 * @return {Boolean} true if passes checks
 * @example
 * isJapanese('泣き虫')
 * // => true
 * isJapanese('あア')
 * // => true
 * isJapanese('２月') // Zenkaku numbers allowed
 * // => true
 * isJapanese('泣き虫。！〜＄') // Zenkaku/JA punctuation
 * // => true
 * isJapanese('泣き虫.!~$') // Latin punctuation fails
 * // => false
 * isJapanese('A泣き虫')
 * // => false
 * isJapanese('≪偽括弧≫', /[≪≫]/);
 * // => true
 */function isJapanese(t="",e){const n=typeOf(e)==="regexp";return!isEmpty(t)&&[...t].every((t=>{const a=isCharJapanese(t);return n?a||e.test(t):a}))}var D=Number.isNaN||function ponyfill(t){return typeof t==="number"&&t!==t};function isEqual(t,e){return t===e||!(!D(t)||!D(e))}function areInputsEqual(t,e){if(t.length!==e.length)return false;for(var n=0;n<t.length;n++)if(!isEqual(t[n],e[n]))return false;return true}function memoizeOne(t,e){e===void 0&&(e=areInputsEqual);var n=null;function memoized(){var a=[];for(var r=0;r<arguments.length;r++)a[r]=arguments[r];if(n&&n.lastThis===this&&e(a,n.lastArgs))return n.lastResult;var o=t.apply(this,a);n={lastResult:o,lastArgs:a,lastThis:this};return o}memoized.clear=function clear(){n=null};return memoized}var _=Object.prototype.hasOwnProperty;function find(t,e,n){for(n of t.keys())if(dequal(n,e))return n}function dequal(t,e){var n,a,r;if(t===e)return true;if(t&&e&&(n=t.constructor)===e.constructor){if(n===Date)return t.getTime()===e.getTime();if(n===RegExp)return t.toString()===e.toString();if(n===Array){if((a=t.length)===e.length)while(a--&&dequal(t[a],e[a]));return a===-1}if(n===Set){if(t.size!==e.size)return false;for(a of t){r=a;if(r&&typeof r==="object"){r=find(e,r);if(!r)return false}if(!e.has(r))return false}return true}if(n===Map){if(t.size!==e.size)return false;for(a of t){r=a[0];if(r&&typeof r==="object"){r=find(e,r);if(!r)return false}if(!dequal(a[1],e.get(r)))return false}return true}if(n===ArrayBuffer){t=new Uint8Array(t);e=new Uint8Array(e)}else if(n===DataView){if((a=t.byteLength)===e.byteLength)while(a--&&t.getInt8(a)===e.getInt8(a));return a===-1}if(ArrayBuffer.isView(t)){if((a=t.byteLength)===e.byteLength)while(a--&&t[a]===e[a]);return a===-1}if(!n||typeof t==="object"){a=0;for(n in t){if(_.call(t,n)&&++a&&!_.call(e,n))return false;if(!(n in e)||!dequal(t[n],e[n]))return false}return Object.keys(e).length===a}}return t!==t&&e!==e}
/**
 * Easy re-use of merging with default options
 * @param {Object} opts user options
 * @returns user options merged over default options
 */const mergeWithDefaultOptions=(t={})=>Object.assign({},a,t);function applyMapping(t,e,n){const a=e;function nextSubtree(t,e){const n=t[e];if(n!==void 0)return Object.assign({"":t[""]+e},t[e])}function newChunk(t,e){const n=t.charAt(0);return parse(Object.assign({"":n},a[n]),t.slice(1),e,e+1)}function parse(t,e,a,r){if(!e)return n||Object.keys(t).length===1?t[""]?[[a,r,t[""]]]:[]:[[a,r,null]];if(Object.keys(t).length===1)return[[a,r,t[""]]].concat(newChunk(e,r));const o=nextSubtree(t,e.charAt(0));return o===void 0?[[a,r,t[""]]].concat(newChunk(e,r)):parse(o,e.slice(1),a,r+1)}return newChunk(t,0)}function transform(t){return Object.entries(t).reduce(((t,[e,n])=>{const a=typeOf(n)==="string";t[e]=a?{"":n}:transform(n);return t}),{})}function getSubTreeOf(t,e){return e.split("").reduce(((t,e)=>{t[e]===void 0&&(t[e]={});return t[e]}),t)}
/**
 * Creates a custom mapping tree, returns a function that accepts a defaultMap which the newly created customMapping will be merged with and returned
 * (customMap) => (defaultMap) => mergedMap
 * @param  {Object} customMap { 'ka' : 'な' }
 * @return {Function} (defaultMap) => defaultMergedWithCustomMap
 * @example
 * const sillyMap = createCustomMapping({ 'ちゃ': 'time', '茎': 'cookie'　});
 * // sillyMap is passed defaultMapping to merge with when called in toRomaji()
 * toRomaji("It's 茎 ちゃ よ", { customRomajiMapping: sillyMap });
 * // => 'It's cookie time yo';
 */function createCustomMapping(t={}){const e={};typeOf(t)==="object"&&Object.entries(t).forEach((([t,n])=>{let a=e;t.split("").forEach((t=>{a[t]===void 0&&(a[t]={});a=a[t]}));a[""]=n}));return function makeMap(t){const n=JSON.parse(JSON.stringify(t));function transformMap(t,e){return t===void 0||typeOf(t)==="string"?e:Object.entries(e).reduce(((e,[n,a])=>{e[n]=transformMap(t[n],a);return e}),t)}return transformMap(n,e)}}function mergeCustomMapping(t,e){return e?typeOf(e)==="function"?e(t):createCustomMapping(e)(t):t}const W={a:"あ",i:"い",u:"う",e:"え",o:"お",k:{a:"か",i:"き",u:"く",e:"け",o:"こ"},s:{a:"さ",i:"し",u:"す",e:"せ",o:"そ"},t:{a:"た",i:"ち",u:"つ",e:"て",o:"と"},n:{a:"な",i:"に",u:"ぬ",e:"ね",o:"の"},h:{a:"は",i:"ひ",u:"ふ",e:"へ",o:"ほ"},m:{a:"ま",i:"み",u:"む",e:"め",o:"も"},y:{a:"や",u:"ゆ",o:"よ"},r:{a:"ら",i:"り",u:"る",e:"れ",o:"ろ"},w:{a:"わ",i:"ゐ",e:"ゑ",o:"を"},g:{a:"が",i:"ぎ",u:"ぐ",e:"げ",o:"ご"},z:{a:"ざ",i:"じ",u:"ず",e:"ぜ",o:"ぞ"},d:{a:"だ",i:"ぢ",u:"づ",e:"で",o:"ど"},b:{a:"ば",i:"び",u:"ぶ",e:"べ",o:"ぼ"},p:{a:"ぱ",i:"ぴ",u:"ぷ",e:"ぺ",o:"ぽ"},v:{a:"ゔぁ",i:"ゔぃ",u:"ゔ",e:"ゔぇ",o:"ゔぉ"}};const B={".":"。",",":"、",":":"：","/":"・","!":"！","?":"？","~":"〜","-":"ー","‘":"「","’":"」","“":"『","”":"』","[":"［","]":"］","(":"（",")":"）","{":"｛","}":"｝"};const G={k:"き",s:"し",t:"ち",n:"に",h:"ひ",m:"み",r:"り",g:"ぎ",z:"じ",d:"ぢ",b:"び",p:"ぴ",v:"ゔ",q:"く",f:"ふ"};const V={ya:"ゃ",yi:"ぃ",yu:"ゅ",ye:"ぇ",yo:"ょ"};const F={a:"ぁ",i:"ぃ",u:"ぅ",e:"ぇ",o:"ぉ"};const X={sh:"sy",ch:"ty",cy:"ty",chy:"ty",shy:"sy",j:"zy",jy:"zy",shi:"si",chi:"ti",tsu:"tu",ji:"zi",fu:"hu"};const Q=Object.assign({tu:"っ",wa:"ゎ",ka:"ヵ",ke:"ヶ"},F,V);const Y={yi:"い",wu:"う",ye:"いぇ",wi:"うぃ",we:"うぇ",kwa:"くぁ",whu:"う",tha:"てゃ",thu:"てゅ",tho:"てょ",dha:"でゃ",dhu:"でゅ",dho:"でょ"};const Z={wh:"う",kw:"く",qw:"く",q:"く",gw:"ぐ",sw:"す",ts:"つ",th:"て",tw:"と",dh:"で",dw:"ど",fw:"ふ",f:"ふ"};function createRomajiToKanaMap$1(){const t=transform(W);const subtreeOf=e=>getSubTreeOf(t,e);Object.entries(G).forEach((([t,e])=>{Object.entries(V).forEach((([n,a])=>{subtreeOf(t+n)[""]=e+a}))}));Object.entries(B).forEach((([t,e])=>{subtreeOf(t)[""]=e}));Object.entries(Z).forEach((([t,e])=>{Object.entries(F).forEach((([n,a])=>{const r=subtreeOf(t+n);r[""]=e+a}))}));["n","n'","xn"].forEach((t=>{subtreeOf(t)[""]="ん"}));t.c=JSON.parse(JSON.stringify(t.k));Object.entries(X).forEach((([t,e])=>{const n=t.slice(0,t.length-1);const a=t.charAt(t.length-1);const r=subtreeOf(n);r[a]=JSON.parse(JSON.stringify(subtreeOf(e)))}));function getAlternatives(t){return[...Object.entries(X),["c","k"]].reduce(((e,[n,a])=>t.startsWith(a)?e.concat(t.replace(a,n)):e),[])}Object.entries(Q).forEach((([t,e])=>{const last=t=>t.charAt(t.length-1);const allExceptLast=t=>t.slice(0,t.length-1);const n=`x${t}`;const a=subtreeOf(n);a[""]=e;const r=subtreeOf(`l${allExceptLast(t)}`);r[last(t)]=a;getAlternatives(t).forEach((e=>{["l","x"].forEach((n=>{const a=subtreeOf(n+allExceptLast(e));a[last(e)]=subtreeOf(n+t)}))}))}));Object.entries(Y).forEach((([t,e])=>{subtreeOf(t)[""]=e}));function addTsu(t){return Object.entries(t).reduce(((t,[e,n])=>{t[e]=e?addTsu(n):`っ${n}`;return t}),{})}[...Object.keys(G),"c","y","w","j"].forEach((e=>{const n=t[e];n[e]=addTsu(n)}));delete t.n.n;return Object.freeze(JSON.parse(JSON.stringify(t)))}let tt=null;function getRomajiToKanaTree(){tt==null&&(tt=createRomajiToKanaMap$1());return tt}const et=createCustomMapping({wi:"ゐ",we:"ゑ"});function IME_MODE_MAP(t){const e=JSON.parse(JSON.stringify(t));e.n.n={"":"ん"};e.n[" "]={"":"ん"};return e}
/**
 * Tests if char is in English unicode uppercase range
 * @param  {String} char
 * @return {Boolean}
 */function isCharUpperCase(t=""){return!isEmpty(t)&&isCharInRange(t,r,o)}
/**
 * Returns true if char is 'ー'
 * @param  {String} char to test
 * @return {Boolean}
 */function isCharLongDash(t=""){return!isEmpty(t)&&t.charCodeAt(0)===y}
/**
 * Tests if char is '・'
 * @param  {String} char
 * @return {Boolean} true if '・'
 */function isCharSlashDot(t=""){return!isEmpty(t)&&t.charCodeAt(0)===j}
/**
 * Tests a character. Returns true if the character is [Hiragana](https://en.wikipedia.org/wiki/Hiragana).
 * @param  {String} char character string to test
 * @return {Boolean}
 */function isCharHiragana(t=""){return!isEmpty(t)&&(!!isCharLongDash(t)||isCharInRange(t,l,f))}
/**
 * Convert [Hiragana](https://en.wikipedia.org/wiki/Hiragana) to [Katakana](https://en.wikipedia.org/wiki/Katakana)
 * Passes through any non-hiragana chars
 * @private
 * @param  {String} [input=''] text input
 * @return {String} converted text
 * @example
 * hiraganaToKatakana('ひらがな')
 * // => "ヒラガナ"
 * hiraganaToKatakana('ひらがな is a type of kana')
 * // => "ヒラガナ is a type of kana"
 */function hiraganaToKatakana(t=""){const e=[];t.split("").forEach((t=>{if(isCharLongDash(t)||isCharSlashDot(t))e.push(t);else if(isCharHiragana(t)){const n=t.charCodeAt(0)+(p-l);const a=String.fromCharCode(n);e.push(a)}else e.push(t)}));return e.join("")}const nt=memoizeOne(((t,e,n)=>{let a=getRomajiToKanaTree();a=t?IME_MODE_MAP(a):a;a=e?et(a):a;n&&(a=mergeCustomMapping(a,n));return a}),dequal);
/**
 * Convert [Romaji](https://en.wikipedia.org/wiki/Romaji) to [Kana](https://en.wikipedia.org/wiki/Kana), lowercase text will result in [Hiragana](https://en.wikipedia.org/wiki/Hiragana) and uppercase text will result in [Katakana](https://en.wikipedia.org/wiki/Katakana).
 * @param  {String} [input=''] text
 * @param  {DefaultOptions} [options=defaultOptions]
 * @param  {Object.<string, string>} [map] custom mapping
 * @return {String} converted text
 * @example
 * toKana('onaji BUTTSUUJI')
 * // => 'おなじ ブッツウジ'
 * toKana('ONAJI buttsuuji')
 * // => 'オナジ ぶっつうじ'
 * toKana('座禅‘zazen’スタイル')
 * // => '座禅「ざぜん」スタイル'
 * toKana('batsuge-mu')
 * // => 'ばつげーむ'
 * toKana('!?.:/,~-‘’“”[](){}') // Punctuation conversion
 * // => '！？。：・、〜ー「」『』［］（）｛｝'
 * toKana('we', { useObsoleteKana: true })
 * // => 'ゑ'
 * toKana('wanakana', { customKanaMapping: { na: 'に', ka: 'bana' } });
 * // => 'わにbanaに'
 */function toKana(t="",n={},a){let r;if(a)r=n;else{r=mergeWithDefaultOptions(n);a=nt(r.IMEMode,r.useObsoleteKana,r.customKanaMapping)}return splitIntoConvertedKana(t,r,a).map((n=>{const[a,o,i]=n;if(i===null)return t.slice(a);const s=r.IMEMode===e.HIRAGANA;const c=r.IMEMode===e.KATAKANA||[...t.slice(a,o)].every(isCharUpperCase);return s||!c?i:hiraganaToKatakana(i)})).join("")}
/**
 *
 * @private
 * @param {String} [input=''] input text
 * @param {DefaultOptions} [options=defaultOptions] toKana options
 * @param {Object} [map] custom mapping
 * @returns {Array[]} [[start, end, token]]
 * @example
 * splitIntoConvertedKana('buttsuuji')
 * // => [[0, 2, 'ぶ'], [2, 6, 'っつ'], [6, 7, 'う'], [7, 9, 'じ']]
 */function splitIntoConvertedKana(t="",e={},n){const{IMEMode:a,useObsoleteKana:r,customKanaMapping:o}=e;n||(n=nt(a,r,o));return applyMapping(t.toLowerCase(),n,!a)}let at=[];
/**
 * Automagically replaces input values with converted text to kana
 * @param  {defaultOptions} [options] user config overrides, default conversion is toKana()
 * @return {Function} event handler with bound options
 * @private
 */function makeOnInput(t){let e;const n=Object.assign({},mergeWithDefaultOptions(t),{IMEMode:t.IMEMode||true});const a=nt(n.IMEMode,n.useObsoleteKana,n.customKanaMapping);const r=[...Object.keys(a),...Object.keys(a).map((t=>t.toUpperCase()))];return function onInput({target:t}){t.value!==e&&t.dataset.ignoreComposition!=="true"&&convertInput(t,n,a,r)}}function convertInput(t,e,n,a,r){const[o,i,s]=splitInput(t.value,t.selectionEnd,a);const c=toKana(i,e,n);const u=i!==c;if(u){const e=o.length+c.length;const n=o+c+s;t.value=n;s.length?setTimeout((()=>t.setSelectionRange(e,e)),1):t.setSelectionRange(e,e)}else t.value}function onComposition({type:t,target:e,data:n}){const a=/Mac/.test(window.navigator&&window.navigator.platform);if(a){t==="compositionupdate"&&isJapanese(n)&&(e.dataset.ignoreComposition="true");t==="compositionend"&&(e.dataset.ignoreComposition="false")}}function trackListeners(t,e,n){at=at.concat({id:t,inputHandler:e,compositionHandler:n})}function untrackListeners({id:t}){at=at.filter((({id:e})=>e!==t))}function findListeners(t){return t&&at.find((({id:e})=>e===t.getAttribute("data-wanakana-id")))}function splitInput(t="",e=0,n=[]){let a;let r;let o;if(e===0&&n.includes(t[0]))[a,r,o]=workFromStart(t,n);else if(e>0)[a,r,o]=workBackwards(t,e);else{[a,r]=takeWhileAndSlice(t,(t=>!n.includes(t)));[r,o]=takeWhileAndSlice(r,(t=>!isJapanese(t)))}return[a,r,o]}function workFromStart(t,e){return["",...takeWhileAndSlice(t,(t=>e.includes(t)||!isJapanese(t,/[0-9]/)))]}function workBackwards(t="",e=0){const[n,a]=takeWhileAndSlice([...t.slice(0,e)].reverse(),(t=>!isJapanese(t)));return[a.reverse().join(""),n.split("").reverse().join(""),t.slice(e)]}function takeWhileAndSlice(t={},e=(t=>!!t)){const n=[];const{length:a}=t;let r=0;while(r<a&&e(t[r],r)){n.push(t[r]);r+=1}return[n.join(""),t.slice(r)]}const onInput=({target:{value:t,selectionStart:e,selectionEnd:n}})=>console.log("input:",{value:t,selectionStart:e,selectionEnd:n});const onCompositionStart=()=>console.log("compositionstart");const onCompositionUpdate=({target:{value:t,selectionStart:e,selectionEnd:n},data:a})=>console.log("compositionupdate",{data:a,value:t,selectionStart:e,selectionEnd:n});const onCompositionEnd=()=>console.log("compositionend");const rt={input:onInput,compositionstart:onCompositionStart,compositionupdate:onCompositionUpdate,compositionend:onCompositionEnd};const addDebugListeners=t=>{Object.entries(rt).forEach((([e,n])=>t.addEventListener(e,n)))};const removeDebugListeners=t=>{Object.entries(rt).forEach((([e,n])=>t.removeEventListener(e,n)))};const ot=["TEXTAREA","INPUT"];let it=0;const newId=()=>{it+=1;return`${Date.now()}${it}`};
/**
 * Binds eventListener for 'input' events to an input field to automagically replace values with kana
 * Can pass `{ IMEMode: 'toHiragana' || 'toKatakana' }` to enforce kana conversion type
 * @param  {HTMLInputElement | HTMLTextAreaElement} element textarea, input[type="text"] etc
 * @param  {DefaultOptions} [options=defaultOptions] defaults to { IMEMode: true } using `toKana`
 * @example
 * bind(document.querySelector('#myInput'));
 */function bind(t={},e={},n=false){if(!ot.includes(t.nodeName))throw new Error(`Element provided to Wanakana bind() was not a valid input or textarea element.\n Received: (${JSON.stringify(t)})`);if(t.hasAttribute("data-wanakana-id"))return;const a=makeOnInput(e);const r=newId();const o=[{name:"data-wanakana-id",value:r},{name:"lang",value:"ja"},{name:"autoCapitalize",value:"none"},{name:"autoCorrect",value:"off"},{name:"autoComplete",value:"off"},{name:"spellCheck",value:"false"}];const i={};o.forEach((e=>{i[e.name]=t.getAttribute(e.name);t.setAttribute(e.name,e.value)}));t.dataset.previousAttributes=JSON.stringify(i);t.addEventListener("input",a);t.addEventListener("compositionupdate",onComposition);t.addEventListener("compositionend",onComposition);trackListeners(r,a,onComposition);n===true&&addDebugListeners(t)}
/**
 * Unbinds eventListener from input field
 * @param  {HTMLInputElement | HTMLTextAreaElement} element textarea, input
 */function unbind(t,e=false){const n=findListeners(t);if(n==null)throw new Error(`Element provided to Wanakana unbind() had no listener registered.\n Received: ${JSON.stringify(t)}`);const{inputHandler:a,compositionHandler:r}=n;const o=JSON.parse(t.dataset.previousAttributes);Object.keys(o).forEach((e=>{o[e]?t.setAttribute(e,o[e]):t.removeAttribute(e)}));t.removeAttribute("data-previous-attributes");t.removeAttribute("data-ignore-composition");t.removeEventListener("input",a);t.removeEventListener("compositionstart",r);t.removeEventListener("compositionupdate",r);t.removeEventListener("compositionend",r);untrackListeners(n);e===true&&removeDebugListeners(t)}
/**
 * Tests a character. Returns true if the character is [Romaji](https://en.wikipedia.org/wiki/Romaji) (allowing [Hepburn romanisation](https://en.wikipedia.org/wiki/Hepburn_romanization))
 * @param  {String} char character string to test
 * @return {Boolean}
 */function isCharRomaji(t=""){return!isEmpty(t)&&x.some((([e,n])=>isCharInRange(t,e,n)))}
/**
 * Test if `input` is [Romaji](https://en.wikipedia.org/wiki/Romaji) (allowing [Hepburn romanisation](https://en.wikipedia.org/wiki/Hepburn_romanization))
 * @param  {String} [input=''] text
 * @param  {RegExp} [allowed] additional test allowed to pass for each char
 * @return {Boolean} true if [Romaji](https://en.wikipedia.org/wiki/Romaji)
 * @example
 * isRomaji('Tōkyō and Ōsaka')
 * // => true
 * isRomaji('12a*b&c-d')
 * // => true
 * isRomaji('あアA')
 * // => false
 * isRomaji('お願い')
 * // => false
 * isRomaji('a！b&cーd') // Zenkaku punctuation fails
 * // => false
 * isRomaji('a！b&cーd', /[！ー]/)
 * // => true
 */function isRomaji(t="",e){const n=typeOf(e)==="regexp";return!isEmpty(t)&&[...t].every((t=>{const a=isCharRomaji(t);return n?a||e.test(t):a}))}
/**
 * Tests a character. Returns true if the character is [Katakana](https://en.wikipedia.org/wiki/Katakana).
 * @param  {String} char character string to test
 * @return {Boolean}
 */function isCharKatakana(t=""){return isCharInRange(t,p,h)}
/**
 * Tests a character. Returns true if the character is [Hiragana](https://en.wikipedia.org/wiki/Hiragana) or [Katakana](https://en.wikipedia.org/wiki/Katakana).
 * @param  {String} char character string to test
 * @return {Boolean}
 */function isCharKana(t=""){return!isEmpty(t)&&(isCharHiragana(t)||isCharKatakana(t))}
/**
 * Test if `input` is [Kana](https://en.wikipedia.org/wiki/Kana) ([Katakana](https://en.wikipedia.org/wiki/Katakana) and/or [Hiragana](https://en.wikipedia.org/wiki/Hiragana))
 * @param  {String} [input=''] text
 * @return {Boolean} true if all [Kana](https://en.wikipedia.org/wiki/Kana)
 * @example
 * isKana('あ')
 * // => true
 * isKana('ア')
 * // => true
 * isKana('あーア')
 * // => true
 * isKana('A')
 * // => false
 * isKana('あAア')
 * // => false
 */function isKana(t=""){return!isEmpty(t)&&[...t].every(isCharKana)}
/**
 * Test if `input` is [Hiragana](https://en.wikipedia.org/wiki/Hiragana)
 * @param  {String} [input=''] text
 * @return {Boolean} true if all [Hiragana](https://en.wikipedia.org/wiki/Hiragana)
 * @example
 * isHiragana('げーむ')
 * // => true
 * isHiragana('A')
 * // => false
 * isHiragana('あア')
 * // => false
 */function isHiragana(t=""){return!isEmpty(t)&&[...t].every(isCharHiragana)}
/**
 * Test if `input` is [Katakana](https://en.wikipedia.org/wiki/Katakana)
 * @param  {String} [input=''] text
 * @return {Boolean} true if all [Katakana](https://en.wikipedia.org/wiki/Katakana)
 * @example
 * isKatakana('ゲーム')
 * // => true
 * isKatakana('あ')
 * // => false
 * isKatakana('A')
 * // => false
 * isKatakana('あア')
 * // => false
 */function isKatakana(t=""){return!isEmpty(t)&&[...t].every(isCharKatakana)}
/**
 * Returns true if char is '々'
 * @param  {String} char to test
 * @return {Boolean}
 */function isCharIterationMark(t=""){return!isEmpty(t)&&t.charCodeAt(0)===d}
/**
 * Tests a character. Returns true if the character is a CJK ideograph (kanji).
 * @param  {String} char character string to test
 * @return {Boolean}
 */function isCharKanji(t=""){return isCharInRange(t,g,m)||isCharIterationMark(t)}
/**
 * Tests if `input` is [Kanji](https://en.wikipedia.org/wiki/Kanji) ([Japanese CJK ideographs](https://en.wikipedia.org/wiki/CJK_Unified_Ideographs))
 * @param  {String} [input=''] text
 * @return {Boolean} true if all [Kanji](https://en.wikipedia.org/wiki/Kanji)
 * @example
 * isKanji('刀')
 * // => true
 * isKanji('切腹')
 * // => true
 * isKanji('勢い')
 * // => false
 * isKanji('あAア')
 * // => false
 * isKanji('🐸')
 * // => false
 */function isKanji(t=""){return!isEmpty(t)&&[...t].every(isCharKanji)}
/**
 * Test if `input` contains a mix of [Romaji](https://en.wikipedia.org/wiki/Romaji) *and* [Kana](https://en.wikipedia.org/wiki/Kana), defaults to pass through [Kanji](https://en.wikipedia.org/wiki/Kanji)
 * @param  {String} input text
 * @param  {{ passKanji: Boolean}} [options={ passKanji: true }] optional config to pass through kanji
 * @return {Boolean} true if mixed
 * @example
 * isMixed('Abあア'))
 * // => true
 * isMixed('お腹A')) // ignores kanji by default
 * // => true
 * isMixed('お腹A', { passKanji: false }))
 * // => false
 * isMixed('ab'))
 * // => false
 * isMixed('あア'))
 * // => false
 */function isMixed(t="",e={passKanji:true}){const n=[...t];let a=false;e.passKanji||(a=n.some(isKanji));return(n.some(isHiragana)||n.some(isKatakana))&&n.some(isRomaji)&&!a}const isCharInitialLongDash=(t,e)=>isCharLongDash(t)&&e<1;const isCharInnerLongDash=(t,e)=>isCharLongDash(t)&&e>0;const isKanaAsSymbol=t=>["ヶ","ヵ"].includes(t);const st={a:"あ",i:"い",u:"う",e:"え",o:"う"};function katakanaToHiragana(t="",e,{isDestinationRomaji:n,convertLongVowelMark:a}={}){let r="";return t.split("").reduce(((o,i,s)=>{if(isCharSlashDot(i)||isCharInitialLongDash(i,s)||isKanaAsSymbol(i))return o.concat(i);if(a&&r&&isCharInnerLongDash(i,s)){const a=e(r).slice(-1);return isCharKatakana(t[s-1])&&a==="o"&&n?o.concat("お"):o.concat(st[a])}if(!isCharLongDash(i)&&isCharKatakana(i)){const t=i.charCodeAt(0)+(l-p);const e=String.fromCharCode(t);r=e;return o.concat(e)}r="";return o.concat(i)}),[]).join("")}let ct=null;const ut={"あ":"a","い":"i","う":"u","え":"e","お":"o","か":"ka","き":"ki","く":"ku","け":"ke","こ":"ko","さ":"sa","し":"shi","す":"su","せ":"se","そ":"so","た":"ta","ち":"chi","つ":"tsu","て":"te","と":"to","な":"na","に":"ni","ぬ":"nu","ね":"ne","の":"no","は":"ha","ひ":"hi","ふ":"fu","へ":"he","ほ":"ho","ま":"ma","み":"mi","む":"mu","め":"me","も":"mo","ら":"ra","り":"ri","る":"ru","れ":"re","ろ":"ro","や":"ya","ゆ":"yu","よ":"yo","わ":"wa","ゐ":"wi","ゑ":"we","を":"wo","ん":"n","が":"ga","ぎ":"gi","ぐ":"gu","げ":"ge","ご":"go","ざ":"za","じ":"ji","ず":"zu","ぜ":"ze","ぞ":"zo","だ":"da","ぢ":"ji","づ":"zu","で":"de","ど":"do","ば":"ba","び":"bi","ぶ":"bu","べ":"be","ぼ":"bo","ぱ":"pa","ぴ":"pi","ぷ":"pu","ぺ":"pe","ぽ":"po","ゔぁ":"va","ゔぃ":"vi","ゔ":"vu","ゔぇ":"ve","ゔぉ":"vo"};const lt={"。":".","、":",","：":":","・":"/","！":"!","？":"?","〜":"~","ー":"-","「":"‘","」":"’","『":"“","』":"”","［":"[","］":"]","（":"(","）":")","｛":"{","｝":"}","　":" "};const ft=["あ","い","う","え","お","や","ゆ","よ"];const pt={"ゃ":"ya","ゅ":"yu","ょ":"yo"};const ht={"ぃ":"yi","ぇ":"ye"};const gt={"ぁ":"a","ぃ":"i","ぅ":"u","ぇ":"e","ぉ":"o"};const mt=["き","に","ひ","み","り","ぎ","び","ぴ","ゔ","く","ふ"];const dt={"し":"sh","ち":"ch","じ":"j","ぢ":"j"};const yt={"っ":"","ゃ":"ya","ゅ":"yu","ょ":"yo","ぁ":"a","ぃ":"i","ぅ":"u","ぇ":"e","ぉ":"o"};const jt={b:"b",c:"t",d:"d",f:"f",g:"g",h:"h",j:"j",k:"k",m:"m",p:"p",q:"q",r:"r",s:"s",t:"t",v:"v",w:"w",x:"x",z:"z"};function getKanaToHepburnTree(){ct==null&&(ct=createKanaToHepburnMap());return ct}function getKanaToRomajiTree(t){switch(t){case n.HEPBURN:return getKanaToHepburnTree();default:return{}}}function createKanaToHepburnMap(){const t=transform(ut);const subtreeOf=e=>getSubTreeOf(t,e);const setTrans=(t,e)=>{subtreeOf(t)[""]=e};Object.entries(lt).forEach((([t,e])=>{subtreeOf(t)[""]=e}));[...Object.entries(pt),...Object.entries(gt)].forEach((([t,e])=>{setTrans(t,e)}));mt.forEach((t=>{const e=subtreeOf(t)[""][0];Object.entries(pt).forEach((([n,a])=>{setTrans(t+n,e+a)}));Object.entries(ht).forEach((([n,a])=>{setTrans(t+n,e+a)}))}));Object.entries(dt).forEach((([t,e])=>{Object.entries(pt).forEach((([n,a])=>{setTrans(t+n,e+a[1])}));setTrans(`${t}ぃ`,`${e}yi`);setTrans(`${t}ぇ`,`${e}e`)}));t["っ"]=resolveTsu(t);Object.entries(yt).forEach((([t,e])=>{setTrans(t,e)}));ft.forEach((t=>{setTrans(`ん${t}`,`n'${subtreeOf(t)[""]}`)}));return Object.freeze(JSON.parse(JSON.stringify(t)))}function resolveTsu(t){return Object.entries(t).reduce(((t,[e,n])=>{if(e)t[e]=resolveTsu(n);else{const a=n.charAt(0);t[e]=Object.keys(jt).includes(a)?jt[a]+n:n}return t}),{})}const Ct=memoizeOne(((t,e)=>{let n=getKanaToRomajiTree(t);e&&(n=mergeCustomMapping(n,e));return n}),dequal);
/**
 * Convert kana to romaji
 * @param  {String} kana text input
 * @param  {DefaultOptions} [options=defaultOptions]
 * @param  {Object.<string, string>} [map] custom mapping
 * @return {String} converted text
 * @example
 * toRomaji('ひらがな　カタカナ')
 * // => 'hiragana katakana'
 * toRomaji('げーむ　ゲーム')
 * // => 'ge-mu geemu'
 * toRomaji('ひらがな　カタカナ', { upcaseKatakana: true })
 * // => 'hiragana KATAKANA'
 * toRomaji('つじぎり', { customRomajiMapping: { じ: 'zi', つ: 'tu', り: 'li' } });
 * // => 'tuzigili'
 */function toRomaji(t="",e={},n){const a=mergeWithDefaultOptions(e);n||(n=Ct(a.romanization,a.customRomajiMapping));return splitIntoRomaji(t,a,n).map((e=>{const[n,r,o]=e;const i=a.upcaseKatakana&&isKatakana(t.slice(n,r));return i?o.toUpperCase():o})).join("")}function splitIntoRomaji(t,e,n){n||(n=Ct(e.romanization,e.customRomajiMapping));const a=Object.assign({},{isDestinationRomaji:true},e);return applyMapping(katakanaToHiragana(t,toRomaji,a),n,!e.IMEMode)}
/**
 * Tests a character. Returns true if the character is considered English punctuation.
 * @param  {String} char character string to test
 * @return {Boolean}
 */function isCharEnglishPunctuation(t=""){return!isEmpty(t)&&q.some((([e,n])=>isCharInRange(t,e,n)))}
/**
 * Convert input to [Hiragana](https://en.wikipedia.org/wiki/Hiragana)
 * @param  {String} [input=''] text
 * @param  {DefaultOptions} [options=defaultOptions]
 * @return {String} converted text
 * @example
 * toHiragana('toukyou, オオサカ')
 * // => 'とうきょう、　おおさか'
 * toHiragana('only カナ', { passRomaji: true })
 * // => 'only かな'
 * toHiragana('wi')
 * // => 'うぃ'
 * toHiragana('wi', { useObsoleteKana: true })
 * // => 'ゐ'
 */function toHiragana(t="",e={}){const n=mergeWithDefaultOptions(e);if(n.passRomaji)return katakanaToHiragana(t,toRomaji,n);if(isMixed(t,{passKanji:true})){const e=katakanaToHiragana(t,toRomaji,n);return toKana(e.toLowerCase(),n)}return isRomaji(t)||isCharEnglishPunctuation(t)?toKana(t.toLowerCase(),n):katakanaToHiragana(t,toRomaji,n)}
/**
 * Convert input to [Katakana](https://en.wikipedia.org/wiki/Katakana)
 * @param  {String} [input=''] text
 * @param  {DefaultOptions} [options=defaultOptions]
 * @return {String} converted text
 * @example
 * toKatakana('toukyou, おおさか')
 * // => 'トウキョウ、　オオサカ'
 * toKatakana('only かな', { passRomaji: true })
 * // => 'only カナ'
 * toKatakana('wi')
 * // => 'ウィ'
 * toKatakana('wi', { useObsoleteKana: true })
 * // => 'ヰ'
 */function toKatakana(t="",e={}){const n=mergeWithDefaultOptions(e);if(n.passRomaji)return hiraganaToKatakana(t);if(isMixed(t)||isRomaji(t)||isCharEnglishPunctuation(t)){const e=toKana(t.toLowerCase(),n);return hiraganaToKatakana(e)}return hiraganaToKatakana(t)}
/**
 * Tests a character. Returns true if the character is considered Japanese punctuation.
 * @param  {String} char character string to test
 * @return {Boolean}
 */function isCharJapanesePunctuation(t=""){return!isEmpty(t)&&!isCharIterationMark(t)&&z.some((([e,n])=>isCharInRange(t,e,n)))}const isCharEnSpace=t=>t===" ";const isCharJaSpace=t=>t==="　";const isCharJaNum=t=>/[０-９]/.test(t);const isCharEnNum=t=>/[0-9]/.test(t);const Et={EN:"en",JA:"ja",EN_NUM:"englishNumeral",JA_NUM:"japaneseNumeral",EN_PUNC:"englishPunctuation",JA_PUNC:"japanesePunctuation",KANJI:"kanji",HIRAGANA:"hiragana",KATAKANA:"katakana",SPACE:"space",OTHER:"other"};function getType(t,e=false){const{EN:n,JA:a,EN_NUM:r,JA_NUM:o,EN_PUNC:i,JA_PUNC:s,KANJI:c,HIRAGANA:u,KATAKANA:l,SPACE:f,OTHER:p}=Et;if(e)switch(true){case isCharJaNum(t):return p;case isCharEnNum(t):return p;case isCharEnSpace(t):return n;case isCharEnglishPunctuation(t):return p;case isCharJaSpace(t):return a;case isCharJapanesePunctuation(t):return p;case isCharJapanese(t):return a;case isCharRomaji(t):return n;default:return p}else switch(true){case isCharJaSpace(t):return f;case isCharEnSpace(t):return f;case isCharJaNum(t):return o;case isCharEnNum(t):return r;case isCharEnglishPunctuation(t):return i;case isCharJapanesePunctuation(t):return s;case isCharKanji(t):return c;case isCharHiragana(t):return u;case isCharKatakana(t):return l;case isCharJapanese(t):return a;case isCharRomaji(t):return n;default:return p}}
/**
 * Splits input into array of strings separated by opinionated token types
 * `'en', 'ja', 'englishNumeral', 'japaneseNumeral','englishPunctuation', 'japanesePunctuation','kanji', 'hiragana', 'katakana', 'space', 'other'`.
 * If `{ compact: true }` then many same-language tokens are combined (spaces + text, kanji + kana, numeral + punctuation).
 * If `{ detailed: true }` then return array will contain `{ type, value }` instead of `'value'`
 * @param  {String} input text
 * @param  {{compact: Boolean | undefined, detailed: Boolean | undefined}} [options={ compact: false, detailed: false}] options to modify output style
 * @return {(String[]|Array.<{type: String, value: String}>)} text split into tokens containing values, or detailed object
 * @example
 * tokenize('ふふフフ')
 * // ['ふふ', 'フフ']
 *
 * tokenize('感じ')
 * // ['感', 'じ']
 *
 * tokenize('人々')
 * // ['人々']
 *
 * tokenize('truly 私は悲しい')
 * // ['truly', ' ', '私', 'は', '悲', 'しい']
 *
 * tokenize('truly 私は悲しい', { compact: true })
 * // ['truly ', '私は悲しい']
 *
 * tokenize('5romaji here...!?人々漢字ひらがなカタ　カナ４「ＳＨＩＯ」。！')
 * // [ '5', 'romaji', ' ', 'here', '...!?', '人々漢字', 'ひらがな', 'カタ', '　', 'カナ', '４', '「', 'ＳＨＩＯ', '」。！']
 *
 * tokenize('5romaji here...!?人々漢字ひらがなカタ　カナ４「ＳＨＩＯ」。！', { compact: true })
 * // [ '5', 'romaji here', '...!?', '人々漢字ひらがなカタ　カナ', '４「', 'ＳＨＩＯ', '」。！']
 *
 * tokenize('5romaji here...!?人々漢字ひらがなカタ　カナ４「ＳＨＩＯ」。！ لنذهب', { detailed: true })
 * // [
 *  { type: 'englishNumeral', value: '5' },
 *  { type: 'en', value: 'romaji' },
 *  { type: 'space', value: ' ' },
 *  { type: 'en', value: 'here' },
 *  { type: 'englishPunctuation', value: '...!?' },
 *  { type: 'kanji', value: '人々漢字' },
 *  { type: 'hiragana', value: 'ひらがな' },
 *  { type: 'katakana', value: 'カタ' },
 *  { type: 'space', value: '　' },
 *  { type: 'katakana', value: 'カナ' },
 *  { type: 'japaneseNumeral', value: '４' },
 *  { type: 'japanesePunctuation', value: '「' },
 *  { type: 'ja', value: 'ＳＨＩＯ' },
 *  { type: 'japanesePunctuation', value: '」。！' },
 *  { type: 'space', value: ' ' },
 *  { type: 'other', value: 'لنذهب' },
 * ]
 *
 * tokenize('5romaji here...!?人々漢字ひらがなカタ　カナ４「ＳＨＩＯ」。！ لنذهب', { compact: true, detailed: true})
 * // [
 *  { type: 'other', value: '5' },
 *  { type: 'en', value: 'romaji here' },
 *  { type: 'other', value: '...!?' },
 *  { type: 'ja', value: '人々漢字ひらがなカタ　カナ' },
 *  { type: 'other', value: '４「' },
 *  { type: 'ja', value: 'ＳＨＩＯ' },
 *  { type: 'other', value: '」。！' },
 *  { type: 'en', value: ' ' },
 *  { type: 'other', value: 'لنذهب' },
 *]
 */function tokenize(t,{compact:e=false,detailed:n=false}={}){if(t==null||isEmpty(t))return[];const a=[...t];let r=a.shift();let o=getType(r,e);r=n?{type:o,value:r}:r;const i=a.reduce(((t,a)=>{const r=getType(a,e);const i=r===o;o=r;let s=a;i&&(s=(n?t.pop().value:t.pop())+s);return n?t.concat({type:r,value:s}):t.concat(s)}),[r]);return i}const isLeadingWithoutInitialKana=(t,e)=>e&&!isKana(t[0]);const isTrailingWithoutFinalKana=(t,e)=>!e&&!isKana(t[t.length-1]);const isInvalidMatcher=(t,e)=>e&&![...e].some(isKanji)||!e&&isKana(t)
/**
 * Strips [Okurigana](https://en.wikipedia.org/wiki/Okurigana)
 * @param  {String} input text
 * @param  {{ leading: Boolean | undefined, matchKanji: string | undefined }} [options={ leading: false, matchKanji: '' }] optional config
 * @return {String} text with okurigana removed
 * @example
 * stripOkurigana('踏み込む')
 * // => '踏み込'
 * stripOkurigana('お祝い')
 * // => 'お祝'
 * stripOkurigana('お腹', { leading: true });
 * // => '腹'
 * stripOkurigana('ふみこむ', { matchKanji: '踏み込む' });
 * // => 'ふみこ'
 * stripOkurigana('おみまい', { matchKanji: 'お祝い', leading: true });
 * // => 'みまい'
 */;function stripOkurigana(t="",{leading:e=false,matchKanji:n=""}={}){if(!isJapanese(t)||isLeadingWithoutInitialKana(t,e)||isTrailingWithoutFinalKana(t,e)||isInvalidMatcher(t,n))return t;const a=n||t;const r=new RegExp(e?`^${tokenize(a).shift()}`:`${tokenize(a).pop()}$`);return t.replace(r,"")}export{n as ROMANIZATIONS,e as TO_KANA_METHODS,t as VERSION,bind,isHiragana,isJapanese,isKana,isKanji,isKatakana,isMixed,isRomaji,stripOkurigana,toHiragana,toKana,toKatakana,toRomaji,tokenize,unbind};

