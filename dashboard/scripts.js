// ============================================
// Configuration
// ============================================
// CONFIG is now loaded from config.js

// ============================================
// Colorblind-Friendly Palette
// ============================================
const COLORS = {
    blue: '#0077BB',
    orange: '#EE7733',
    teal: '#009988',
    red: '#CC3311',
    cyan: '#33BBEE',
    purple: '#AA3377',
    yellow: '#DDAA33',
    pink: '#EE3377',
    green: '#117733'
};

const COLOR_ARRAY = Object.values(COLORS);

// ============================================
// Global State
// ============================================
let rawData = null;
let filteredData = null;
let trendChart = null;
let breakdownChart = null;

// ============================================
// DOM Elements
// ============================================
const elements = {
    themeToggle: document.getElementById('themeToggle'),
    serviceSelector: document.getElementById('serviceSelector'),
    startDate: document.getElementById('startDate'),
    endDate: document.getElementById('endDate'),
    lastUpdatedTime: document.getElementById('lastUpdatedTime'),
    trendChart: document.getElementById('trendChart'),
    breakdownChart: document.getElementById('breakdownChart'),
    downloadCsv: document.getElementById('downloadCsv'),
    downloadJson: document.getElementById('downloadJson'),
    messageContainer: document.getElementById('messageContainer')
};

// ============================================
// Initialization
// ============================================
document.addEventListener('DOMContentLoaded', () => {
    initializeTheme();
    initializeEventListeners();
    loadData();
});

// ============================================
// Theme Management
// ============================================
function initializeTheme() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);
}

function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    
    // Update charts with new theme
    if (trendChart && breakdownChart) {
        updateChartsTheme();
    }
}

function updateChartsTheme() {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const textColor = isDark ? '#E9ECEF' : '#212529';
    const gridColor = isDark ? '#3A3F4A' : '#DEE2E6';
    
    const themeOptions = {
        color: textColor,
        plugins: {
            legend: {
                labels: { color: textColor }
            }
        },
        scales: {
            x: {
                ticks: { color: textColor },
                grid: { color: gridColor }
            },
            y: {
                ticks: { color: textColor },
                grid: { color: gridColor }
            }
        }
    };
    
    if (trendChart) {
        Object.assign(trendChart.options, themeOptions);
        trendChart.update();
    }
    
    if (breakdownChart) {
        Object.assign(breakdownChart.options, themeOptions);
        breakdownChart.update();
    }
}

// ============================================
// Event Listeners
// ============================================
function initializeEventListeners() {
    elements.themeToggle.addEventListener('click', toggleTheme);
    elements.serviceSelector.addEventListener('change', handleServiceChange);
    elements.startDate.addEventListener('change', handleDateRangeChange);
    elements.endDate.addEventListener('change', handleDateRangeChange);
    elements.downloadCsv.addEventListener('click', downloadCsv);
    elements.downloadJson.addEventListener('click', downloadJson);
}

// ============================================
// Data Loading
// ============================================
async function loadData() {
    try {
        showMessage('Loading cost data...', 'info');
        
        const response = await fetch(CONFIG.dataUrl);
        
        if (!response.ok) {
            throw new Error(`Failed to load data: ${response.status} ${response.statusText}`);
        }
        
        // const data = await response.json();
          const awsData = await response.json();
        
         // Transform AWS Cost Explorer format to internal format
        const transformedData = transformAwsData(awsData);
        
        if (!transformedData || !transformedData.data || transformedData.data.length === 0) {
            showMessage('No cost data available. Please check back later.', 'error');
            return;
        }
        
       rawData = transformedData;
       filteredData = [...transformedData.data];
        
        initializeUI();
        updateCharts();
        
        clearMessages();
        showMessage('Data loaded successfully!', 'success', 2000);
        
    } catch (error) {
        console.error('Error loading data:', error);
        showMessage(`Error loading data: ${error.message}`, 'error');
    }
}

// ============================================
// AWS Data Transformation
// ============================================
function transformAwsData(awsData) {
    // Check if data is already in the expected format
    if (awsData.data && Array.isArray(awsData.data)) {
        return awsData;
    }
    
    // Transform AWS Cost Explorer format
    if (!awsData.ResultsByTime || !Array.isArray(awsData.ResultsByTime)) {
        throw new Error('Invalid AWS Cost Explorer data format');
    }
    
    const transformedData = {
        lastUpdated: new Date().toISOString(),
        data: []
    };
    
    // Process each time period
    awsData.ResultsByTime.forEach(timePeriod => {
        const dateEntry = {
            date: timePeriod.TimePeriod.Start,
            services: {}
        };
        
        // Process groups (services)
        if (timePeriod.Groups && Array.isArray(timePeriod.Groups)) {
            timePeriod.Groups.forEach(group => {
                // Extract service name from Keys array
                const serviceName = group.Keys[0];
                
                // Extract cost from Metrics
                const cost = parseFloat(group.Metrics.UnblendedCost.Amount);
                
                // Only add services with non-zero costs
                if (cost > 0) {
                    dateEntry.services[serviceName] = cost;
                }
            });
        }
        
        // Only add date entries that have at least one service with cost
        if (Object.keys(dateEntry.services).length > 0) {
            transformedData.data.push(dateEntry);
        }
    });
    
    // Add metadata from AWS response if available
    if (awsData.ResponseMetadata) {
        transformedData.metadata = {
            requestId: awsData.ResponseMetadata.RequestId,
            timestamp: new Date().toISOString()
        };
    }
    
    return transformedData;
}


// ============================================
// UI Initialization
// ============================================
function initializeUI() {
    // Update last updated timestamp
    if (rawData.lastUpdated) {
        const date = new Date(rawData.lastUpdated);
        elements.lastUpdatedTime.textContent = date.toLocaleString(CONFIG.dateFormat, {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        elements.lastUpdatedTime.setAttribute('datetime', rawData.lastUpdated);
    }
    
    // Populate service selector
    const services = extractServices();
    elements.serviceSelector.innerHTML = '<option value="total">Total (All Services)</option>';
    services.forEach(service => {
        const option = document.createElement('option');
        option.value = service;
        option.textContent = service;
        elements.serviceSelector.appendChild(option);
    });
    
    // Set date range defaults
    const dates = rawData.data.map(d => d.date).sort();
    elements.startDate.value = dates[0];
    elements.endDate.value = dates[dates.length - 1];
    elements.startDate.min = dates[0];
    elements.startDate.max = dates[dates.length - 1];
    elements.endDate.min = dates[0];
    elements.endDate.max = dates[dates.length - 1];
}

// ============================================
// Data Processing
// ============================================
function extractServices() {
    const servicesSet = new Set();
    rawData.data.forEach(day => {
        Object.keys(day.services).forEach(service => servicesSet.add(service));
    });
    return Array.from(servicesSet).sort();
}

function filterDataByDateRange() {
    const startDate = elements.startDate.value;
    const endDate = elements.endDate.value;
    
    filteredData = rawData.data.filter(day => {
        return day.date >= startDate && day.date <= endDate;
    });
    
    updateCharts();
}

// ============================================
// Chart Rendering
// ============================================
function updateCharts() {
    updateTrendChart();
    updateBreakdownChart();
}

function updateTrendChart() {
    const selectedService = elements.serviceSelector.value;
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const textColor = isDark ? '#E9ECEF' : '#212529';
    const gridColor = isDark ? '#3A3F4A' : '#DEE2E6';
    
    const labels = filteredData.map(d => {
        const date = new Date(d.date);
        return date.toLocaleDateString(CONFIG.dateFormat, { month: 'short', day: 'numeric' });
    });
    
    let data;
    if (selectedService === 'total') {
        data = filteredData.map(d => {
            return Object.values(d.services).reduce((sum, cost) => sum + cost, 0);
        });
    } else {
        data = filteredData.map(d => d.services[selectedService] || 0);
    }
    
    const chartData = {
        labels: labels,
        datasets: [{
            label: selectedService === 'total' ? 'Total Cost' : selectedService,
            data: data,
            borderColor: COLORS.blue,
            backgroundColor: COLORS.blue + '20',
            borderWidth: 3,
            fill: true,
            tension: 0.4,
            pointRadius: 4,
            pointHoverRadius: 6,
            pointBackgroundColor: COLORS.blue,
            pointBorderColor: '#FFFFFF',
            pointBorderWidth: 2
        }]
    };
    
    const config = {
        type: 'line',
        data: chartData,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: true,
                    position: 'top',
                    labels: {
                        color: textColor,
                        font: { size: 14, weight: '600' },
                        padding: 15
                    }
                },
                tooltip: {
                    backgroundColor: isDark ? '#2C3038' : '#FFFFFF',
                    titleColor: textColor,
                    bodyColor: textColor,
                    borderColor: gridColor,
                    borderWidth: 1,
                    padding: 12,
                    displayColors: true,
                    callbacks: {
                        label: (context) => {
                            return `Cost: $${context.parsed.y.toFixed(2)}`;
                        }
                    }
                }
            },
            scales: {
                x: {
                    ticks: { color: textColor },
                    grid: { color: gridColor, display: false }
                },
                y: {
                    ticks: {
                        color: textColor,
                        callback: (value) => `$${value.toFixed(0)}`
                    },
                    grid: { color: gridColor },
                    beginAtZero: true
                }
            }
        }
    };
    
    if (trendChart) {
        trendChart.destroy();
    }
    
    trendChart = new Chart(elements.trendChart, config);
}

function updateBreakdownChart() {
    const services = extractServices();
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const textColor = isDark ? '#E9ECEF' : '#212529';
    const gridColor = isDark ? '#3A3F4A' : '#DEE2E6';
    
    const labels = filteredData.map(d => {
        const date = new Date(d.date);
        return date.toLocaleDateString(CONFIG.dateFormat, { month: 'short', day: 'numeric' });
    });
    
    const datasets = services.map((service, index) => {
        return {
            label: service,
            data: filteredData.map(d => d.services[service] || 0),
            backgroundColor: COLOR_ARRAY[index % COLOR_ARRAY.length],
            borderColor: '#FFFFFF',
            borderWidth: 1
        };
    });
    
    const chartData = {
        labels: labels,
        datasets: datasets
    };
    
    const config = {
        type: 'bar',
        data: chartData,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: true,
                    position: 'top',
                    labels: {
                        color: textColor,
                        font: { size: 12, weight: '600' },
                        padding: 10,
                        usePointStyle: true
                    }
                },
                tooltip: {
                    backgroundColor: isDark ? '#2C3038' : '#FFFFFF',
                    titleColor: textColor,
                    bodyColor: textColor,
                    borderColor: gridColor,
                    borderWidth: 1,
                    padding: 12,
                    callbacks: {
                        label: (context) => {
                            return `${context.dataset.label}: $${context.parsed.y.toFixed(2)}`;
                        },
                        footer: (tooltipItems) => {
                            const total = tooltipItems.reduce((sum, item) => sum + item.parsed.y, 0);
                            return `Total: $${total.toFixed(2)}`;
                        }
                    }
                }
            },
            scales: {
                x: {
                    stacked: true,
                    ticks: { color: textColor },
                    grid: { color: gridColor, display: false }
                },
                y: {
                    stacked: true,
                    ticks: {
                        color: textColor,
                        callback: (value) => `$${value.toFixed(0)}`
                    },
                    grid: { color: gridColor },
                    beginAtZero: true
                }
            }
        }
    };
    
    if (breakdownChart) {
        breakdownChart.destroy();
    }
    
    breakdownChart = new Chart(elements.breakdownChart, config);
}

// ============================================
// Event Handlers
// ============================================
function handleServiceChange() {
    updateTrendChart();
}

function handleDateRangeChange() {
    filterDataByDateRange();
}

// ============================================
// CSV Export
// ============================================
function downloadCsv() {
    try {
        const csv = generateWeeklyCsv();
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        
        const today = new Date().toISOString().split('T')[0];
        link.setAttribute('href', url);
        link.setAttribute('download', `weekly-costs-${today}.csv`);
        link.style.visibility = 'hidden';
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        showMessage('CSV downloaded successfully!', 'success', 2000);
    } catch (error) {
        console.error('Error generating CSV:', error);
        showMessage('Error generating CSV file', 'error');
    }
}

function generateWeeklyCsv() {
    const services = extractServices();
    const weeklyData = groupByWeek(filteredData);
    
    // CSV Header
    let csv = 'Week Start,Week End,' + services.join(',') + ',Total\n';
    
    // CSV Rows
    weeklyData.forEach(week => {
        const serviceCosts = services.map(service => {
            const cost = week.services[service] || 0;
            return cost.toFixed(2);
        });
        
        const total = Object.values(week.services).reduce((sum, cost) => sum + cost, 0);
        
        csv += `${week.startDate},${week.endDate},${serviceCosts.join(',')},${total.toFixed(2)}\n`;
    });
    
    return csv;
}

function groupByWeek(data) {
    const weeks = [];
    let currentWeek = null;
    
    data.forEach(day => {
        const date = new Date(day.date);
        const weekStart = getWeekStart(date);
        const weekStartStr = weekStart.toISOString().split('T')[0];
        
        if (!currentWeek || currentWeek.startDate !== weekStartStr) {
            if (currentWeek) {
                weeks.push(currentWeek);
            }
            
            const weekEnd = new Date(weekStart);
            weekEnd.setDate(weekEnd.getDate() + 6);
            
            currentWeek = {
                startDate: weekStartStr,
                endDate: weekEnd.toISOString().split('T')[0],
                services: {}
            };
        }
        
        // Aggregate costs
        Object.entries(day.services).forEach(([service, cost]) => {
            currentWeek.services[service] = (currentWeek.services[service] || 0) + cost;
        });
    });
    
    if (currentWeek) {
        weeks.push(currentWeek);
    }
    
    return weeks;
}

function getWeekStart(date) {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day; // Adjust to Sunday
    return new Date(d.setDate(diff));
}

// ============================================
// JSON Export
// ============================================
function downloadJson() {
    try {
        const jsonData = {
            lastUpdated: rawData.lastUpdated,
            dateRange: {
                start: elements.startDate.value,
                end: elements.endDate.value
            },
            data: filteredData
        };
        
        const blob = new Blob([JSON.stringify(jsonData, null, 2)], { type: 'application/json' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        
        const today = new Date().toISOString().split('T')[0];
        link.setAttribute('href', url);
        link.setAttribute('download', `cost-data-${today}.json`);
        link.style.visibility = 'hidden';
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        showMessage('JSON downloaded successfully!', 'success', 2000);
    } catch (error) {
        console.error('Error downloading JSON:', error);
        showMessage('Error downloading JSON file', 'error');
    }
}

// ============================================
// Message Display
// ============================================
function showMessage(text, type = 'info', duration = null) {
    const message = document.createElement('div');
    message.className = `message message-${type}`;
    message.textContent = text;
    message.setAttribute('role', 'alert');
    
    elements.messageContainer.appendChild(message);
    
    if (duration) {
        setTimeout(() => {
            message.remove();
        }, duration);
    }
}

function clearMessages() {
    elements.messageContainer.innerHTML = '';
}
