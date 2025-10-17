#!/bin/bash

trap "echo ERR trap triggered" ERR

function failing_function() {
    return 1
}

failing_function
