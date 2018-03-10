
local iconv = require("iconv")

function createIconv(from,to,text)  

  local cd = iconv.new(to .. "//TRANSLIT", from)

  local ostr, err = cd:iconv(text)

  if err == iconv.ERROR_INCOMPLETE then
    return "ERROR: Incomplete input."
  elseif err == iconv.ERROR_INVALID then
    return "ERROR: Invalid input."
  elseif err == iconv.ERROR_NO_MEMORY then
    return "ERROR: Failed to allocate memory."
  elseif err == iconv.ERROR_UNKNOWN then
    return "ERROR: There was an unknown error."
  end
  return ostr
end

function strSplit(inputstr, sep)
    if sep == nil then
      sep = "%s"
    end
    local t={}
    local i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
       t[i] = str
       i = i + 1
    end
    return t
end

local function explode(_str, seperator)
	local pos, arr = 0, {}
                for st, sp in function() return string.find( _str, seperator, pos, true ) end do
                        table.insert( arr, string.sub( _str, pos, st-1 ) )
                        pos = sp + 1
                end
        table.insert( arr, string.sub( _str, pos ) )
        return arr
end

function writeFile(fileData, fileName)
	local file,error = io.open(fileName,"wb+")
	if(file) then
		file:write(fileData)
		file:close()
		file = nil
	end
end

function saveFile(body_data,requestContentType, filePath)
	local boundary = "--" .. string.sub(requestContentType,31)
	local body_data_table = explode(tostring(body_data),boundary)
	local first_string = table.remove(body_data_table,1)
	local last_string = table.remove(body_data_table)
	local fileType,fileName,fileData
	for i,v in ipairs(body_data_table) do
		local start_pos,end_pos,capture,capture2,capture3 = string.find(v,'Content%-Disposition: form%-data; name="(.+)"; filename="(.*)"\r\nContent%-Type: .-\r\n\r\n(.*)\r\n$')
		if(start_pos) then
			fileType = capture
			fileName = capture2
			fileData = capture3
		end
	end
	writeFile(fileData,filePath..fileName)
end




local filePath = "/usr/local/nginx/files/"

--response_data
local resp_body = ngx.arg[1];
ngx.ctx.buffered = (ngx.ctx.buffered or "") .. resp_body
local encoding = ngx.header["Content-Encoding"]
local contentType = ngx.header["Content-Type"]
ngx.var.resp_content_encoding = encoding
ngx.var.resp_content_type = contentType
if (ngx.arg[2])
then
   if(contentType == "application/msword")
   then
	local contentDispos = ngx.header["Content-Disposition"]
	local start_pos,end_pos,fileName = string.find(contentDispos,'filename=(.*)')
	if(fileName)
	then
		fileName = createIconv("GBK","utf-8",fileName)
		writeFile(ngx.ctx.buffered, filePath..fileName)
	end
   else
  	 local t = strSplit(contentType, "=")
  	 local type = t[2]
  	 if(type and type ~= "utf8" and type ~= "utf-8" and type ~= "UTF-8" and type ~= "UTF8")
  	 then
		  ngx.var.resp_body = createIconv(type, "utf-8", ngx.ctx.buffered)
  	 else
		  ngx.var.resp_body = ngx.ctx.buffered
  	 end
    end
end

--request_data(save file)
receive_headers = ngx.req.get_headers()
local requestContentType = receive_headers["content-type"]
local body_data = ngx.req.get_body_data()
if requestContentType 
then
	requestType = string.sub(requestContentType,1,20)
	if(requestType == "multipart/form-data;")
	then
		saveFile(body_data,requestContentType,filePath)
	else	
		ngx.var._request_body = body_data	
	end
else
	ngx.var._request_body = body_data	
end

					

