var rawdata;

function popupPluginInfo(tr) {
  var info = tr.querySelector('.plugin_info');
  if(info) {
    info.style.display = (info.style.display === "none" ? "" : "none");
    return ;
  }
  var plug = tr.getAttribute('data-name');
  var html = '<div class="plugin_info">';
  var data;
  var td = tr.lastChild;
  rawdata.forEach(function(d){
    if(d.plugin.name === plug) {
      if(!data) {
        data = d;
        html += '<h2><a href="'+data.plugin.repo+'">' + data.plugin.name +'</a> by ' + data.plugin.author + '</h2>';
        html += '<h3>Users('+tr.getAttribute('data-count')+')</h3>';
      }
      html += '<li><a href="' + d.config.url + '">' + d.config.author + '</a></li>';
    }
  });
  html += '<ul>';
  td.innerHTML += html + '</ul></div>';
}

function json(path, callback) {
  var xhr = new XMLHttpRequest();
  xhr.open('GET', path, false);
  xhr.onreadystatechange = function() {
    if(xhr.readyState === 4) {
      callback(JSON.parse(xhr.responseText));
    }
  };
  xhr.send(null);
}

json('plugins.json', function(data){
  var max = Math.max.apply(null, data.map(function(d){ return d[1]; }));
  var html = "";
  data.forEach(function(d){
    html += '<tr data-count="'+d[1]+'" data-name="'+d[0]+'" class="plugin_name"><th>' + d[0] + '</th><td><p style="width: ' + (d[1] / max) * 100 + '%;">' + d[1] +'</p></td></tr>';
  });
  document.querySelector('body').innerHTML += '<table>' + html + '</table>';
});

json('raw.json', function(data){
  rawdata = data;
});

document.addEventListener('click', function(e){
  if(e.button === 0) {
    var target = e.target;
    while(target !== document.body) {
      if(target.className === "plugin_name") {
        popupPluginInfo(target);
        break;
      }
      target = target.parentNode;
    }
  }
}, false);
