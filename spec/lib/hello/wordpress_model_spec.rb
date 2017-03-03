require 'spec_helper'

describe Hello::WordpressModel do
  it 'should deserialize strings that are already in the correct format' do
    string = 'a:20:{s:2:"ID";i:63390;s:4:"slug";s:18:"my-hello-bar-25915";s:4:"name";s:12:"My Hello Bar";s:7:"user_id";s:5:"45996";s:9:"parent_id";i:0;s:7:"message";s:18:"This is my message";s:8:"linktext";s:4:"Link";s:12:"feedlinktext";s:9:"Read More";s:7:"linkurl";s:23:"http://www.hellobar.com";s:4:"type";s:4:"feed";s:7:"feedurl";s:0:"";s:7:"twitter";s:0:"";s:7:"enabled";b:1;s:4:"meta";a:22:{s:15:"twitterOverride";s:1:"0";s:8:"barcolor";s:7:"#5ac1e0";s:9:"textcolor";s:7:"#2b2b2b";s:9:"linkcolor";s:7:"#047dba";s:10:"fontFamily";s:26:"Helvetica,Arial,sans-serif";s:8:"closable";s:4:"true";s:8:"showWait";s:2:"-1";s:9:"hideAfter";s:2:"-1";s:10:"wiggleWait";s:5:"60000";s:11:"positioning";s:6:"sticky";s:7:"overlap";s:3:"300";s:13:"twitterFilter";s:4:"true";s:15:"feedCacheExpire";s:4:"3600";s:11:"targetBlank";s:1:"0";s:7:"tabSide";s:5:"right";s:9:"linkStyle";s:14:"button-default";s:10:"imageStyle";s:12:"light-images";s:7:"texture";s:0:"";s:6:"border";s:1:"1";s:11:"bordercolor";s:4:"#fff";s:15:"hideDestination";s:1:"1";s:3:"pro";s:4:"true";}s:11:"custom_html";s:0:"";s:10:"custom_css";s:0:"";s:9:"custom_js";s:0:"";s:6:"status";s:7:"publish";s:7:"created";s:19:"2012-05-10 12:00:13";s:8:"modified";s:19:"2012-11-01 17:48:51";}'

    hash = Hello::WordpressModel.deserialize(string)

    assert hash.is_a?(Hash)
    assert_equal 63_390, hash['ID']
  end

  it 'should deserialize strings that have weird padding' do
    string = 's:1221:"a:20:{s:2:"ID";i:63390;s:4:"slug";s:18:"my-hello-bar-25915";s:4:"name";s:12:"My Hello Bar";s:7:"user_id";s:5:"45996";s:9:"parent_id";i:0;s:7:"message";s:18:"This is my message";s:8:"linktext";s:4:"Link";s:12:"feedlinktext";s:9:"Read More";s:7:"linkurl";s:23:"http://www.hellobar.com";s:4:"type";s:4:"feed";s:7:"feedurl";s:0:"";s:7:"twitter";s:0:"";s:7:"enabled";b:1;s:4:"meta";a:22:{s:15:"twitterOverride";s:1:"0";s:8:"barcolor";s:7:"#5ac1e0";s:9:"textcolor";s:7:"#2b2b2b";s:9:"linkcolor";s:7:"#047dba";s:10:"fontFamily";s:26:"Helvetica,Arial,sans-serif";s:8:"closable";s:4:"true";s:8:"showWait";s:2:"-1";s:9:"hideAfter";s:2:"-1";s:10:"wiggleWait";s:5:"60000";s:11:"positioning";s:6:"sticky";s:7:"overlap";s:3:"300";s:13:"twitterFilter";s:4:"true";s:15:"feedCacheExpire";s:4:"3600";s:11:"targetBlank";s:1:"0";s:7:"tabSide";s:5:"right";s:9:"linkStyle";s:14:"button-default";s:10:"imageStyle";s:12:"light-images";s:7:"texture";s:0:"";s:6:"border";s:1:"1";s:11:"bordercolor";s:4:"#fff";s:15:"hideDestination";s:1:"1";s:3:"pro";s:4:"true";}s:11:"custom_html";s:0:"";s:10:"custom_css";s:0:"";s:9:"custom_js";s:0:"";s:6:"status";s:7:"publish";s:7:"created";s:19:"2012-05-10 12:00:13";s:8:"modified";s:19:"2012-11-01 17:48:51";}";'

    hash = Hello::WordpressModel.deserialize(string)

    assert hash.is_a?(Hash)
    assert_equal 63_390, hash['ID']
  end
end
