import Chart from 'chart.js/auto'

export const employeeCountPerDesignatedCompany = {
  mounted() {
    const ctx = this.el.getContext('2d');

    const config = {
      type: 'pie',
      data: {
        labels: [],
        datasets: [{
          backgroundColor: [],
          data: []
        }]
      },
      options: {
        plugins: {
          legend: {
            display: true,
            position: 'right',
            labels: {
              generateLabels: chart => {
                const datasets = chart.data.datasets;

                return datasets[0].data.map((data, i) => ({
                  text: `${chart.data.labels[i]} - ${data}`,
                  fillStyle: datasets[0].backgroundColor[i],
                }))
              }
            }
          }
        }
      }
    }

    const chart = new Chart(ctx, config);

    this.handleEvent("employee_count_per_assigned_company", ({ data }) => {
      const values = Object.values(data)

      chart.data.labels = Object.keys(data)
      chart.data.datasets[0].data = values.map(value => value.count)
      chart.data.datasets[0].backgroundColor = values.map(value => value.color)

      chart.update()
    })
  }
}
