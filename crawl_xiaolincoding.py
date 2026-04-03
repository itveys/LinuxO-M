#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
from bs4 import BeautifulSoup
import time
import os
import re
import html
from weasyprint import HTML, CSS
from weasyprint.text.fonts import FontConfiguration

BASE_URL = "https://xiaolincoding.com"

ALL_ARTICLES = {
    "图解网络": [
        "/network/1_base/tcp_ip_model.html",
        "/network/1_base/what_happen_url.html",
        "/network/1_base/how_os_deal_network_package.html",
        "/network/2_http/http_interview.html",
        "/network/2_http/http_optimize.html",
        "/network/2_http/https_rsa.html",
        "/network/2_http/https_ecdhe.html",
        "/network/2_http/https_optimize.html",
        "/network/2_http/http2.html",
        "/network/2_http/http3.html",
        "/network/2_http/http_rpc.html",
        "/network/2_http/http_websocket.html",
        "/network/3_tcp/tcp_interview.html",
        "/network/3_tcp/tcp_feature.html",
        "/network/3_tcp/tcp_tcpdump.html",
        "/network/3_tcp/tcp_queue.html",
        "/network/3_tcp/tcp_optimize.html",
        "/network/3_tcp/tcp_stream.html",
        "/network/3_tcp/isn_deff.html",
        "/network/3_tcp/syn_drop.html",
        "/network/3_tcp/out_of_order_fin.html",
        "/network/3_tcp/time_wait_recv_syn.html",
        "/network/3_tcp/tcp_down_and_crash.html",
        "/network/3_tcp/tcp_unplug_the_network_cable.html",
        "/network/3_tcp/tcp_tw_reuse_close.html",
        "/network/3_tcp/tcp_tls.html",
        "/network/3_tcp/tcp_http_keepalive.html",
        "/network/3_tcp/tcp_problem.html",
        "/network/3_tcp/quic.html",
        "/network/3_tcp/port.html",
        "/network/3_tcp/tcp_no_listen.html",
        "/network/3_tcp/tcp_no_accpet.html",
        "/network/3_tcp/tcp_drop.html",
        "/network/3_tcp/tcp_three_fin.html",
        "/network/3_tcp/tcp_seq_ack.html",
        "/network/4_ip/ip_base.html",
        "/network/4_ip/ping.html",
        "/network/4_ip/ping_lo.html",
        "/network/5_learn/learn_network.html",
        "/network/5_learn/draw.html",
    ],
    "图解系统": [
        "/os/1_hardware/how_cpu_run.html",
        "/os/1_hardware/storage.html",
        "/os/1_hardware/how_to_make_cpu_run_faster.html",
        "/os/1_hardware/cpu_mesi.html",
        "/os/1_hardware/how_cpu_deal_task.html",
        "/os/1_hardware/soft_interrupt.html",
        "/os/1_hardware/float.html",
        "/os/2_os_structure/linux_vs_windows.html",
        "/os/3_memory/vmem.html",
        "/os/3_memory/malloc.html",
        "/os/3_memory/mem_reclaim.html",
        "/os/3_memory/alloc_mem.html",
        "/os/3_memory/cache_lru.html",
        "/os/3_memory/linux_mem.html",
        "/os/3_memory/linux_mem2.html",
        "/os/4_process/process_base.html",
        "/os/4_process/process_commu.html",
        "/os/4_process/multithread_sync.html",
        "/os/4_process/deadlock.html",
        "/os/4_process/pessim_and_optimi_lock.html",
        "/os/4_process/create_thread_max.html",
        "/os/4_process/thread_crash.html",
        "/os/5_schedule/schedule.html",
        "/os/6_file_system/file_system.html",
        "/os/6_file_system/pagecache.html",
        "/os/7_device/device.html",
        "/os/8_network_system/zero_copy.html",
        "/os/8_network_system/selete_poll_epoll.html",
        "/os/8_network_system/reactor.html",
        "/os/8_network_system/hash.html",
        "/os/9_linux_cmd/linux_network.html",
        "/os/9_linux_cmd/pv_uv.html",
        "/os/10_learn/learn_os.html",
        "/os/10_learn/draw.html",
    ],
    "图解MySQL": [
        "/mysql/base/how_select.html",
        "/mysql/base/row_format.html",
        "/mysql/index/index_interview.html",
        "/mysql/index/page.html",
        "/mysql/index/why_index_chose_bpuls_tree.html",
        "/mysql/index/2000w.html",
        "/mysql/index/index_lose.html",
        "/mysql/index/count.html",
        "/mysql/index/limit.html",
        "/mysql/transaction/mvcc.html",
        "/mysql/transaction/phantom.html",
        "/mysql/lock/mysql_lock.html",
        "/mysql/lock/how_to_lock.html",
        "/mysql/lock/update_index.html",
        "/mysql/lock/lock_phantom.html",
        "/mysql/lock/deadlock.html",
        "/mysql/lock/show_lock.html",
        "/mysql/log/how_update.html",
        "/mysql/buffer_pool/buffer_pool.html",
    ],
    "图解Redis": [
        "/redis/base/wath_is_redis.html",
        "/redis/base/redis_interview.html",
        "/redis/data_struct/command.html",
        "/redis/data_struct/data_struct.html",
        "/redis/storage/aof.html",
        "/redis/storage/rdb.html",
        "/redis/storage/bigkey_aof_rdb.html",
        "/redis/module/strategy.html",
        "/redis/cluster/master_slave_replication.html",
        "/redis/cluster/sentinel.html",
        "/redis/cluster/cluster.html",
        "/redis/cluster/cache_problem.html",
        "/redis/architecture/mysql_redis_consistency.html",
    ],
    "面试八股": [
        "/interview/java.html",
        "/interview/collections.html",
        "/interview/juc.html",
        "/interview/jvm.html",
        "/interview/spring.html",
        "/interview/cpp.html",
        "/interview/golang.html",
        "/interview/mysql.html",
        "/interview/redis.html",
        "/interview/os.html",
        "/interview/network.html",
        "/interview/data.html",
        "/interview/mq.html",
        "/interview/cap.html",
        "/interview/systemdesign.html",
        "/interview/linux.html",
        "/interview/git.html",
        "/interview/test_dev.html",
        "/interview/business_testing.html",
        "/interview/python_automation.html",
        "/interview/java_automation.html",
        "/interview/performance_testing.html",
        "/interview/win.html",
    ],
}

def fetch_article(url_path):
    url = BASE_URL + url_path
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(url, headers=headers, timeout=30)
        response.encoding = 'utf-8'
        return response.text
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return None

def extract_content(html_content):
    if not html_content:
        return None, None
    
    soup = BeautifulSoup(html_content, 'html.parser')
    
    content_div = soup.find('div', class_='content') or soup.find('article') or soup.find('main')
    if not content_div:
        content_div = soup.find('div', id='app') or soup.body
    
    if not content_div:
        return None, None
    
    title_elem = soup.find('h1')
    title = title_elem.get_text().strip() if title_elem else "无标题"
    
    for script in content_div.find_all('script'):
        script.decompose()
    for style in content_div.find_all('style'):
        style.decompose()
    for nav in content_div.find_all('nav'):
        nav.decompose()
    
    for elem in content_div.find_all(class_=re.compile('(sidebar|footer|header|nav|menu|comment)', re.I)):
        elem.decompose()
    
    for img in content_div.find_all('img'):
        src = img.get('src', '')
        if src and not src.startswith('http'):
            if src.startswith('//'):
                img['src'] = 'https:' + src
            elif src.startswith('/'):
                img['src'] = BASE_URL + src
            else:
                img['src'] = BASE_URL + '/' + src
    
    return title, str(content_div)

def generate_html_book(all_content, output_file):
    html_template = '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>小林Coding图解系列合集</title>
    <style>
        @page {
            size: A4;
            margin: 2cm;
            @top-center {
                content: "小林Coding图解系列";
                font-size: 10pt;
                color: #666;
            }
            @bottom-center {
                content: counter(page);
                font-size: 10pt;
            }
        }
        
        body {
            font-family: "Noto Sans SC", "WenQuanYi Micro Hei", "Microsoft YaHei", SimSun, sans-serif;
            font-size: 12pt;
            line-height: 1.8;
            color: #333;
            max-width: 100%;
        }
        
        h1 {
            font-size: 28pt;
            color: #2c3e50;
            text-align: center;
            padding: 40px 0;
            border-bottom: 3px solid #3498db;
            margin-bottom: 30px;
            page-break-before: always;
        }
        
        h1:first-of-type {
            page-break-before: avoid;
        }
        
        .book-title {
            font-size: 36pt;
            text-align: center;
            padding: 100px 0 50px 0;
            color: #2c3e50;
            border-bottom: none;
        }
        
        .book-subtitle {
            font-size: 16pt;
            text-align: center;
            color: #666;
            margin-bottom: 50px;
        }
        
        .toc {
            page-break-after: always;
            padding: 20px 0;
        }
        
        .toc h2 {
            font-size: 20pt;
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        
        .toc-section {
            margin: 20px 0;
        }
        
        .toc-section-title {
            font-size: 14pt;
            font-weight: bold;
            color: #34495e;
            margin: 15px 0 10px 0;
        }
        
        .toc-item {
            margin: 5px 0 5px 20px;
            color: #555;
        }
        
        h2 {
            font-size: 18pt;
            color: #2980b9;
            border-left: 4px solid #3498db;
            padding-left: 15px;
            margin-top: 30px;
        }
        
        h3 {
            font-size: 14pt;
            color: #27ae60;
            margin-top: 25px;
        }
        
        h4 {
            font-size: 12pt;
            color: #8e44ad;
            margin-top: 20px;
        }
        
        p {
            text-align: justify;
            margin: 10px 0;
        }
        
        code {
            background-color: #f4f4f4;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: "Fira Code", "Source Code Pro", Consolas, monospace;
            font-size: 10pt;
        }
        
        pre {
            background-color: #f8f8f8;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            overflow-x: auto;
            font-size: 9pt;
            line-height: 1.5;
            page-break-inside: avoid;
        }
        
        pre code {
            background-color: transparent;
            padding: 0;
        }
        
        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 20px auto;
            page-break-inside: avoid;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            page-break-inside: avoid;
        }
        
        th, td {
            border: 1px solid #ddd;
            padding: 10px;
            text-align: left;
        }
        
        th {
            background-color: #3498db;
            color: white;
        }
        
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        
        blockquote {
            border-left: 4px solid #3498db;
            margin: 20px 0;
            padding: 10px 20px;
            background-color: #f0f7fb;
            color: #555;
        }
        
        .section-divider {
            page-break-before: always;
        }
        
        .chapter-title {
            font-size: 24pt;
            color: #2c3e50;
            text-align: center;
            padding: 50px 0;
            border-bottom: 2px solid #3498db;
            margin-bottom: 30px;
        }
        
        ul, ol {
            margin: 10px 0;
            padding-left: 30px;
        }
        
        li {
            margin: 5px 0;
        }
        
        .highlight {
            background-color: #fff3cd;
            padding: 2px 5px;
        }
        
        .tip {
            background-color: #d4edda;
            border: 1px solid #c3e6cb;
            padding: 15px;
            border-radius: 5px;
            margin: 15px 0;
        }
        
        .warning {
            background-color: #f8d7da;
            border: 1px solid #f5c6cb;
            padding: 15px;
            border-radius: 5px;
            margin: 15px 0;
        }
    </style>
</head>
<body>
'''
    
    html_content = html_template
    
    html_content += '''
<div class="book-title">小林Coding图解系列合集</div>
<div class="book-subtitle">图解计算机网络、操作系统、MySQL、Redis + 面试八股文</div>
<div class="book-subtitle">共 1500 张图 + 100 万字</div>
'''
    
    html_content += '''
<div class="toc">
<h2>目录</h2>
'''
    
    for section_name, articles in all_content.items():
        html_content += f'''
<div class="toc-section">
<div class="toc-section-title">{section_name} ({len(articles)} 篇)</div>
'''
        for title, _ in articles:
            html_content += f'<div class="toc-item">• {title}</div>\n'
        html_content += '</div>\n'
    
    html_content += '</div>\n'
    
    for section_name, articles in all_content.items():
        html_content += f'<div class="chapter-title">{section_name}</div>\n'
        
        for title, content in articles:
            if content:
                html_content += f'''
<div class="section-divider">
<h1>{title}</h1>
{content}
</div>
'''
    
    html_content += '''
</body>
</html>
'''
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    return output_file

def html_to_pdf(html_file, pdf_file):
    font_config = FontConfiguration()
    
    html = HTML(filename=html_file)
    
    html.write_pdf(pdf_file, font_config=font_config)
    
    return pdf_file

def main():
    print("=" * 60)
    print("小林Coding网站内容提取工具")
    print("=" * 60)
    
    all_content = {}
    total_articles = sum(len(articles) for articles in ALL_ARTICLES.values())
    current = 0
    
    for section_name, url_paths in ALL_ARTICLES.items():
        print(f"\n正在处理: {section_name}")
        print("-" * 40)
        
        all_content[section_name] = []
        
        for url_path in url_paths:
            current += 1
            print(f"[{current}/{total_articles}] 获取: {url_path}")
            
            html_content = fetch_article(url_path)
            if html_content:
                title, content = extract_content(html_content)
                if title and content:
                    all_content[section_name].append((title, content))
                    print(f"    ✓ 成功: {title}")
                else:
                    print(f"    ✗ 解析失败")
            else:
                print(f"    ✗ 获取失败")
            
            time.sleep(0.5)
    
    print("\n" + "=" * 60)
    print("生成HTML文件...")
    
    html_file = "xiaolincoding_book.html"
    generate_html_book(all_content, html_file)
    print(f"✓ HTML文件已生成: {html_file}")
    
    print("\n生成PDF文件...")
    pdf_file = "xiaolincoding_book.pdf"
    try:
        html_to_pdf(html_file, pdf_file)
        print(f"✓ PDF文件已生成: {pdf_file}")
    except Exception as e:
        print(f"PDF生成失败: {e}")
        print("请检查weasyprint是否正确安装")
    
    print("\n" + "=" * 60)
    print("完成!")
    print("=" * 60)

if __name__ == "__main__":
    main()
