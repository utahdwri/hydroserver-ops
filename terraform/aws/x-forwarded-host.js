function handler(event) {
    var request = event.request;
    var headers = request.headers;
    var host = request.headers.host.value;
    // Set x-forwarded-host header equal to host header
    headers['x-forwarded-host'] = {value: host};

    return request;
}
