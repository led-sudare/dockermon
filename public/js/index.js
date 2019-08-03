const chartColors = {
    red: 'rgb(255, 99, 132)',
    orange: 'rgb(255, 159, 64)',
    yellow: 'rgb(255, 205, 86)',
    green: 'rgb(75, 192, 192)',
    blue: 'rgb(54, 162, 235)',
    purple: 'rgb(153, 102, 255)',
    grey: 'rgb(201, 203, 207)'
};

function newWebSocket(charts) {
    let ws = new WebSocket('ws://' + window.location.host + '/ws');
    if (!ws) {
        return ws
    }

    ws.onopen = () => console.log('connection opened');
    ws.onclose = () => {
        console.log('connection closed')
        var id = setInterval(function () {
            var ws = newWebSocket(charts);
            if (ws) {
                clearInterval(id);　//idをclearIntervalで指定している
            }
            console.log('try to open ws...')
        }, 2000);
    };
    ws.onmessage = m => {
        var stats = JSON.parse(m.data);
        $.each(stats, (j, s) => {
            chart = charts[s.name];
            chart.data.datasets[0].data.push({
                x: s.time,
                y: s.cpu
            });
            chart.data.datasets[1].data.push({
                x: s.time,
                y: s.mem
            });
        });
    }
    return ws;
}

function createDataSet(i) {
    var data = {
        datasets: [
            {
                label: 'CPU Usage',
                backgroundColor: chartColors.red,
                borderColor: chartColors.red,
                fill: false,
                lineTension: 0,
                borderDash: [8, 4],
                data: []
            },
            {
                label: 'Memory Usage',
                backgroundColor: chartColors.blue,
                borderColor: chartColors.blue,
                fill: false,
                lineTension: 0,
                borderDash: [8, 4],
                data: []
            }
        ]
    };
    return data;
}

function createOption(i) {
    var option = {
        maintainAspectRatio: false,
        scales: {
            xAxes: [{
                type: 'realtime',
                realtime: {
                    duration: 100000
                }
            }],
            yAxes: [{
                ticks: {
                    beginAtZero: true,
                    min: 0,
                    suggestedMax: 100,
                },
            }]
        }
    };
    if (!(i === 0)) {
        option['legend'] = false;
    }
    return option;
}

$(document).ready(() => {

    let charts = {}
    $.get('containers', (data) => {

        $.each(JSON.parse(data), (i, d) => {

            var ctx = document.getElementById(d.name).getContext('2d');
            charts[d.name] = new Chart(ctx, {
                type: 'line',
                data: createDataSet(i),
                options: createOption(i),
            });
        });
        newWebSocket(charts);
    });
});
