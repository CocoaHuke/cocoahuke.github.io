---
layout: page
title: List
permalink: /outline/
---

<ul>
   {% for post in site.posts %}
       <li><a href="{{ site.baseurl }}{{ post.url }}">{{ post.title }}</a></li>
       <br />
   {% endfor %}
</ul>
