#!/bin/sh
jupyter-lab --ip='*' --no-browser --ServerApp.token=$JUPYTERLAB_TOK --ServerApp.password_required='True' --ServerApp.password=$JUPYTERLAB_PWD
