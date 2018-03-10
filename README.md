# nginx_grab_file
关键点：
1.	设置client_body_buffer_size 100m ,如果设置太小或不设置，则文件流被缓存到文件中，会导致request_body获取不到值。
2.	使用lua脚本正则匹配时贪婪模式是.*,否则是.-
3.	使用lua脚本写文件时，默认会失败，是因为nginx默认启动时的用户是nobody，需要在nginx的默认配置nginx.conf上面配置user root，或者把文件目录的拥有者设置成nobody
4.	在保存完文件后想执行ngx.req. set_body_data(“”)将日志中大量的二进制乱码清空，但发现及时在最后执行还是会导致之前通过body_data获取的数据全没了（给人感觉就是先执行了ngx.req. set_body_data(“”)，无论这个放哪），最后解决办法是在日志记录中没有使用nginx自带的变量$request_body而是自定义了一个变量$_request_body，然后再代码中再根据情况赋值（非二进制数据则赋值）
