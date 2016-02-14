---
layout: page
title: Post List
---
<br />
<ul>
   {% for post in site.posts %}
       <li><a href="{{ site.baseurl }}{{ post.url }}">{{ post.title }}</a></li>
       <span class="post-date">{{ post.date | date_to_string }}</span>
       <br />
   {% endfor %}
</ul>