<!-- Template from https://github.com/othneildrew/Best-README-Template -->
<a id="readme-top"></a>


<!-- PROJECT LOGO -->
<div align="center">
  <h2 align="center">A Desktop Debian XFCE Docker image</h2>

  <p align="center">
    A lightweight ready to go image using x2go.
    <br />
  </p>
</div>

This project is originally forked from [https://github.com/melroy89/xfcevdi]. It has been ported to Debian Trixie (latest stable release), and somewhat simplified.

<!-- GETTING STARTED -->
## Getting started
Build then run the image.
```sh
podman build -t xfcevdi_dev .
podman run --shm-size 2g -it --rm -p 2222:22 -v "${PWD}":/home/user/workspace -e USERNAME=user -e PASS=user xfcevdi_dev:latest
```


<!-- LICENCE -->
## Licence
[![License: GPL v3][gpl3-badge]][gpl3-url]

This work is licensed under a GNU GPL v3 licence.


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[gpl3-url]: https://www.gnu.org/licenses/gpl-3.0
[gpl3-badge]: https://img.shields.io/badge/License-GPLv3-blue.svg
