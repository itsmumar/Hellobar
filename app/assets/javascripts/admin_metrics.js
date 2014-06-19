var allData = {};
var selectedData = {};

function getABTestCertainty(aTotal, aConverted, bTotal, bConverted) {
  var certainty = 0;
  var aConversion = aConverted / aTotal;
  var bConversion = bConverted / bTotal;
  if (aConversion >= 0 && bConversion >= 0) {
    var a_standard_error = Math.sqrt(aConversion * (1 - aConversion) / aTotal);
    var b_standard_error = Math.sqrt(bConversion * (1 - bConversion) / bTotal);
    var zScore = (aConversion - bConversion) / Math.sqrt(Math.pow(a_standard_error, 2) + Math.pow(b_standard_error, 2));
    if (aConversion > bConversion) {
      certainty = jstat.pnorm(zScore, 0, 1, null, null);
      /* jstat.pnorm is taken from jstat (javascript stats library). It calculates the normal distribution of a function. The first three inputs are (x, mean, SD). The fourth input is a boolean that determines whether to calculate tail distribution or not and defaults to true. The fifth input is arbitrary for our purposes. This function is very similar to NORMDIST in excel. */
    } else {
      certainty = 1 - jstat.pnorm(zScore, 0, 1, null, null);
    }
  }

  return certainty;
}

function formatPercent(val) {
  if (!val)
    return "0%";
  return Math.round(val * 10000) / 100 + "%";
}

function registerTestResults(id, col1, col2) {
  var rows = {};
  var columnNames = {};
  var columnIndexes = {};

  $("#" + id + " .header th").each(function (i, cell) {
    var cell = $(this);
    var column = cell.data("col");
    if (column) {
      columnNames[i] = column;
      columnIndexes[column] = i;
      if (!cell.data("ignore"))
        cell.click(function () {
          selectABTestCol(id, column);
        });
    }
  });
  $("#" + id + " tr").each(function (i, row) {
    row = $(row);
    var rowKey = row.data("row");
    if (rowKey) {
      row.children("th").click(function () {
        selectABTestRow(id, rowKey)
      });
      var rowData = {};
      row.children("td").each(function (j, col) {
        col = $(col);
        var colKey = columnNames[j + 1];
        if (colKey) {
          col.click(function () {
            selectABTestRow(id, rowKey);
            selectABTestCol(id, colKey)
          });
          var data = col.children("span.data").html()
          if (!data)
            data = col.html();
          rowData[colKey] = data;
        }
      });
      rows[rowKey] = rowData;
    }
  });
  allData[id] = {
    columnNames: columnNames,
    rows: rows,
    columnIndexes: columnIndexes
  };
  // Select the default columns
  selectABTestCol1(id, col1);
  selectABTestCol2(id, col2);

  var rowsSelected = 0;
  var sortedRows = [];
  $.each(rows, function (k, v) {
    sortedRows.push({
      key: k,
      data: v
    });
  });
  sortedRows.sort(function (a, b) {
    return (b.data[col2] / b.data[col1]) - (a.data[col2] / a.data[col1]);
  });
  if (sortedRows[0])
    selectABTestRow1(id, sortedRows[0].key);
  if (sortedRows[1])
    selectABTestRow2(id, sortedRows[1].key);
}


function selectABTestCol(id, col) {
  if (!selectedData[id])
    selectedData[id] = {};

  var col1 = selectedData[id].col1;
  var col2 = selectedData[id].col2;

  if (!col1) {
    if (col2) {
      var col2Index = allData[id].columnIndexes[col2];
      var newColIndex = allData[id].columnIndexes[col]
      var sortedIndexes = [col2Index, newColIndex];
      sortedIndexes.sort();

      selectABTestCol1(id, allData[id].columnNames[sortedIndexes[0]]);
      selectABTestCol2(id, allData[id].columnNames[sortedIndexes[1]]);
    } else
      selectABTestCol1(id, col);
  } else if (!col2)
    selectABTestCol2(id, col);
  else {
    if (col == col1)
      selectABTestCol1(id, null);
    else {
      var col1Index = allData[id].columnIndexes[col1];
      var col2Index = allData[id].columnIndexes[col2];
      var newColIndex = allData[id].columnIndexes[col]
      if (newColIndex < col1Index)
        selectABTestCol1(id, col);
      else
        selectABTestCol2(id, col);
    }
  }
}

function selectABTestCol1(id, col1) {
  if (!selectedData[id])
    selectedData[id] = {};
  selectedData[id].col1 = col1;
  updateABResults(id);
}

function selectABTestCol2(id, col2) {
  if (!selectedData[id])
    selectedData[id] = {};
  selectedData[id].col2 = col2;
  updateABResults(id);
}

function selectABTestRow(id, row) {
  if (!selectedData[id])
    selectedData[id] = {};

  if (selectedData[id].lastSelectedRow) {
    selectedData[id].lastSelectedRow = 0;
    selectABTestRow2(id, row);
  } else {
    selectedData[id].lastSelectedRow = 1;
    selectABTestRow1(id, row);
  }

}

function selectABTestRow1(id, row1) {
  if (!selectedData[id])
    selectedData[id] = {};
  if (selectedData[id].row2 != row1)
    selectedData[id].row1 = row1;
  updateABResults(id);
}

function selectABTestRow2(id, row2) {
  if (!selectedData[id])
    selectedData[id] = {};
  if (selectedData[id].row1 != row2)
    selectedData[id].row2 = row2;
  updateABResults(id);
}

function updateABResults(id) {
  $("#" + id + " tr").removeClass("selected-row1 selected-row2");
  $("#" + id + " td").removeClass("selected-col1 selected-col2");
  $("#" + id + " span.percent").hide();
  $("#" + id + "-summary").html("");
  var selected = selectedData[id];
  if (selected.col1) {
    var col1Index = allData[id].columnIndexes[selected.col1];
    var col1Selector = "#" + id + " td:nth-child(" + (col1Index + 1) + ")";

    $(col1Selector).addClass("selected-col1");
    if (selected.col2 && selected.col2 != selected.col1) {
      var col2Index = allData[id].columnIndexes[selected.col2];
      var col2Selector = "#" + id + " td:nth-child(" + (col2Index + 1) + ")";
      $(col2Selector).addClass("selected-col2");


      // Show all percentages
      setTimeout(function () {
        // Update every row
        $("#" + id + " tr").each(function (i, row) {
          row = $(row);
          if (rowKey = row.data("row")) {
            var total = allData[id].rows[rowKey][selected.col1];
            var converted = allData[id].rows[rowKey][selected.col2];

            var conversion = converted / total;
            row.find(".selected-col2 .percent").html("(" + formatPercent(conversion) + ")").show();
          }
        });
      }, 1);
      if (selected.row1) {
        $("#" + id + " tr[data-row='" + selected.row1 + "']").addClass("selected-row1");
        if (selected.row2) {
          $("#" + id + " tr[data-row='" + selected.row2 + "']").addClass("selected-row2");
          // Get the data and add the summary
          var message;
          var total1 = allData[id].rows[selected.row1][selected.col1];
          var total2 = allData[id].rows[selected.row2][selected.col1];
          var converted1 = allData[id].rows[selected.row1][selected.col2];
          var converted2 = allData[id].rows[selected.row2][selected.col2];

          var conversion1 = converted1 / total1;
          var conversion2 = converted2 / total2;
          $("#" + id + " .selected-row1 .selected-col2 .percent").html("(" + formatPercent(conversion1) + ")").show();
          $("#" + id + " .selected-row2 .selected-col2 .percent").html("(" + formatPercent(conversion2) + ")").show();
          var winner, loser;
          if (conversion1 && conversion2) {
            if (conversion1 > conversion2) {
              winner = "1";
              loser = "2";
            } else {
              winner = "2";
              loser = "1";
            }
            var message = eval("selected.row" + winner) + " is beating " + eval("selected.row" + loser) + " by " + formatPercent(eval("conversion" + winner) / eval("conversion" + loser) - 1.0) + " with a certainty of " + formatPercent(getABTestCertainty(total1, converted1, total2, converted2)) + ".";
            $("#" + id + "-summary").html(message);
          }
        }
      }
    }
  }
}
