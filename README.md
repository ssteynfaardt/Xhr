# Xhr

The 90's called, they want their response data back.

## What is Xhr ?

This is a small cross-browser AJAX class with CORS support and jsonP fallback.

At only 5.3K (1.7K gzipped) Xhr is a library small enough to use on any site and bring old browsers up to date.

### Useage 

##### Basics
Do a simple get call to example.com

	new Xhr().get('http://www.example.com');
	
##### Response	
Log the response data once the AJAX call has been successfull.

	var xhr = new Xhr();
	xhr.onsuccess(function(responseData,status){
		console.log(responseData);
		console.log(status);
	});
	xhr.get('http://www.example.com');
	
#### Chaining methods
Xhr supports chaining methods to make writing your code so much easier.
	
	var xhr = new Xhr().onsuccess(function(){console.log('success');}).onerror(function(){console.log('error');}).get('http://www.example.com');
	
### Methods
`URL` : [ _STRING_, _required_ ] - URL to call

`data` : [ _JSON_ _Object_ ] - Data to POST/PUT

`callback` : [ _STRING_ ] - Name of JsonP callback function

- head ( _URL_ )
- options ( _URL_ )
- get ( _URL_ )
- put ( _URL_ , _data_ )
- post ( _URL_ , _data_ )
- delete ( _URL_ )
- jsonp ( _URL_ , _data_ , _callback_  )

### Callbacks

`function` : [ _function_ ] - Each callback takes a function as a parameter, and will be called when the relevant state was triggered.

 - onreadystatechange ( _function_ )
 - onloadstart ( _function_ )
 - onprogress ( _function_ )
 - onload ( _function_ )
 - onerror ( _function_ )
 - onsuccess ( _function_ )
 - onloadend ( _function_ )
 - ontimeout ( _function_ )
 - onabort ( _function_ )