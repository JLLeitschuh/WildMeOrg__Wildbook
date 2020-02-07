<%@ page contentType="text/html; charset=utf-8" language="java" import="org.ecocean.servlet.ServletUtilities,java.util.ArrayList,java.util.List,java.util.ListIterator,java.util.Properties, java.io.FileInputStream, java.io.File, java.io.FileNotFoundException,
java.util.Iterator,
org.ecocean.*,
org.ecocean.media.MediaAsset,
javax.jdo.Query,
java.util.Map, java.util.HashMap,
org.json.JSONObject, org.json.JSONArray,
org.ecocean.servlet.export.ExportExcelFile,
java.util.Collection,
org.joda.time.DateTime,
org.apache.commons.io.FileUtils,
org.apache.commons.lang3.StringEscapeUtils" %>
<%!

private static Encounter getTruthEncounter(Shepherd myShepherd, String individualId) {
    return myShepherd.getEncounter("0e159eb4-9293-4f4d-935b-f2f8871a2097");
}

private static List<Annotation> getMatchPhotoAnnotations(Shepherd myShepherd, MarkedIndividual indiv) {
    List<Annotation> rtn = new ArrayList<Annotation>();
    if (indiv == null) return rtn;
    for (Encounter enc : indiv.getEncounters()) {
        if (Util.collectionIsEmptyOrNull(enc.getAnnotations())) continue;
        for (Annotation ann : enc.getAnnotations()) {
            MediaAsset ma = ann.getMediaAsset();
            if (ma == null) continue;
            //if (backup == null) backup = ann;
            if (ma.hasKeyword("MatchPhoto")) rtn.add(ann);
        }
    }
    //logic here is that if we have > 1 annot, and one of them has >= 1 sibling annot, that indiv gets to use that asset
    if (rtn.size() > 1) {
        Iterator it = rtn.iterator();
        while (it.hasNext()) {
            Annotation ann = (Annotation)it.next();
            int sibCt = Util.collectionSize(ann.getSiblings());
            if ((sibCt < 1) || (rtn.size() < 2)) continue;
            it.remove();
        }
    }
    return rtn;
}

private static void generateData(Shepherd myShepherd, File file, String dtype) throws java.io.IOException {
    String jdoql = "SELECT FROM org.ecocean.Decision";
    Query query = myShepherd.getPM().newQuery(jdoql);
    query.setOrdering("timestamp");
    Collection col = (Collection)query.execute();
    List<Decision> decs = new ArrayList<Decision>(col);
    query.closeAll();

    List rows = new ArrayList<String[]>();
    if ("match".equals(dtype)) {
        String[] head = new String[]{"Enc ID", "Enc Name", "Cat ID", "Cat Name", "Timestamp", "Date/Time", "Time Attr (s)", "Time Match (s)", "User ID", "Username", "Match Enc ID", "Match Enc Name", "Match Cat ID", "Match Cat Name"};
        rows.add(head);
        for (Decision dec : decs) {
            if (!"match".equals(dec.getProperty())) continue;
            JSONObject d = dec.getValue();
            if (d == null) continue;
            String eid = d.optString("id", null);
            if (eid == null) continue;
            Encounter menc = null;
            if (!eid.equals("no-match")) {
                menc = myShepherd.getEncounter(eid);
                if (menc == null) {
                    System.out.println("WARNING queue.generateData() could not find Encounter id=" + eid + " for Decision id=" + dec.getId());
                    continue;
                }
            }
            long initTime = d.optLong("initTime", -1l);
            long attrSaveTime = d.optLong("attrSaveTime", -1l);
            long matchSaveTime = d.optLong("matchSaveTime", -1l);
            String[] row = new String[head.length];
            row[0] = dec.getEncounter().getCatalogNumber();
            row[1] = dec.getEncounter().getEventID();
            if (dec.getEncounter().hasMarkedIndividual()) {
                row[2] = dec.getEncounter().getIndividualID();
                row[3] = dec.getEncounter().getIndividual().getDisplayName();
            } else {
                row[2] = "-";
                row[3] = "";
            }
            row[4] = Long.toString(dec.getTimestamp());
            row[5] = new DateTime(dec.getTimestamp()).toString();
            row[6] = ((initTime > 0l) && (attrSaveTime > 0l)) ? Integer.toString(Math.round((attrSaveTime - initTime) / 1000)) : "";
            row[7] = ((attrSaveTime > 0l) && (matchSaveTime > 0l)) ? Integer.toString(Math.round((matchSaveTime - attrSaveTime) / 1000)) : "";
            row[8] = dec.getUser().getUUID();
            row[9] = dec.getUser().getUsername();
            if (menc == null) {
                row[10] = "-";
                row[11] = "";
                row[12] = "no-match";
                row[13] = "";
            } else {
                row[10] = menc.getCatalogNumber();
                row[11] = menc.getEventID();
                if (menc.hasMarkedIndividual()) {
                    row[12] = menc.getIndividualID();
                    row[13] = menc.getIndividual().getDisplayName();
                } else {
                    row[12] = "-";
                    row[13] = "";
                }
            }
            rows.add(row);
        }

    } else {  //attributes flavor
        String[] head = new String[]{"Enc ID", "Enc Name", "Cat ID", "Cat Name", "Timestamp", "Date/Time", "User ID", "Username", "Color/Pattern ans", "Color/Pattern", "Color/Patt correct", "Life Stage ans", "Life Stage", "Life Stage correct", "Sex ans", "Sex", "Sex correct", "Sex unk ok", "Collar ans", "Collar", "Collar correct", "Collar unk ok", "Ear Tip ans", "Ear Tip", "Ear Tip correct", "Ear Tip swap ok", "Ear Tip unk ok"};
        rows.add(head);
/*
        Map<String,Integer> indMap = new HashMap<String,Integer>();
        for (int i = 0 ; i < head.length ; i++) {
            indMap.put(head[i], i);
        }
*/
        Map<String,String[]> dataMap = new HashMap<String,String[]>();
        for (Decision dec : decs) {
            JSONObject d = dec.getValue();
            if (d == null) continue;
            String mid = d.optString("_multipleId", null);
            if (mid == null) continue;
            if (dataMap.get(mid) == null) dataMap.put(mid, new String[head.length]);
            dataMap.get(mid)[0] = dec.getEncounter().getCatalogNumber();
            dataMap.get(mid)[1] = dec.getEncounter().getEventID();
            if (dec.getEncounter().hasMarkedIndividual()) {
                dataMap.get(mid)[2] = dec.getEncounter().getIndividualID();
                dataMap.get(mid)[3] = dec.getEncounter().getIndividual().getDisplayName();
            } else {
                dataMap.get(mid)[2] = "-";
                dataMap.get(mid)[3] = "";
            }
            dataMap.get(mid)[4] = Long.toString(dec.getTimestamp());
            dataMap.get(mid)[5] = new DateTime(dec.getTimestamp()).toString();
            dataMap.get(mid)[6] = dec.getUser().getUUID();
            dataMap.get(mid)[7] = dec.getUser().getUsername();

            String prop = dec.getProperty();
            if (prop == null) continue;
            Encounter truthEnc = getTruthEncounter(myShepherd, dec.getEncounter().getIndividualID());
            //Integer valI = indMap.get(dec.getProperty());
            String val = d.optString("value", null);
            //if ((val == null) && (d.optJSONArray("value") != null)) val = d.getJSONArray("value").join(", ");

            if (prop.equals("colorPattern")) {
                if (truthEnc != null) dataMap.get(mid)[8] = truthEnc.getPatterningCode();
                dataMap.get(mid)[9] = val;
                dataMap.get(mid)[10] = new Boolean((val != null) && (truthEnc != null) && (truthEnc.getPatterningCode() != null) && truthEnc.getPatterningCode().equals(val)).toString();
            } else if (prop.equals("lifeStage")) {
                if (truthEnc != null) dataMap.get(mid)[11] = truthEnc.getLifeStage();
                dataMap.get(mid)[12] = val;
                dataMap.get(mid)[13] = new Boolean((val != null) && (truthEnc != null) && (truthEnc.getLifeStage() != null) && truthEnc.getLifeStage().equals(val)).toString();
            } else if (prop.equals("sex")) {
                if (truthEnc != null) dataMap.get(mid)[14] = truthEnc.getSex();
                dataMap.get(mid)[15] = val;
                dataMap.get(mid)[16] = new Boolean((val != null) && (truthEnc != null) && (truthEnc.getSex() != null) && truthEnc.getSex().equals(val)).toString();
                dataMap.get(mid)[17] = new Boolean((val != null) && (truthEnc != null) && (truthEnc.getSex() != null) && (truthEnc.getSex().equals(val) || val.equals("unknown"))).toString();
            } else if (prop.equals("collar")) {
                if (truthEnc != null) dataMap.get(mid)[18] = truthEnc.getCollar();
                dataMap.get(mid)[19] = val;
                dataMap.get(mid)[20] = new Boolean((val != null) && (truthEnc != null) && (truthEnc.getCollar() != null) && truthEnc.getCollar().equals(val)).toString();
                dataMap.get(mid)[21] = new Boolean((val != null) && (truthEnc != null) && (truthEnc.getCollar() != null) && (truthEnc.getCollar().equals(val) || val.equals("unknown"))).toString();
            } else if (prop.equals("earTip")) {
                if (truthEnc != null) dataMap.get(mid)[22] = truthEnc.getEarTip();
                dataMap.get(mid)[23] = val;
                dataMap.get(mid)[24] = new Boolean((val != null) && (truthEnc != null) && (truthEnc.getEarTip() != null) && truthEnc.getEarTip().equals(val)).toString();
                dataMap.get(mid)[25] = new Boolean((val != null) && (truthEnc != null) && (truthEnc.getEarTip() != null) && truthEnc.getEarTip().startsWith("yes") && val.startsWith("yes")).toString();
                dataMap.get(mid)[26] = new Boolean((val != null) && (truthEnc != null) && (truthEnc.getEarTip() != null) && (truthEnc.getEarTip().equals(val) || val.equals("unknown") || (truthEnc.getEarTip().equals("unknown") && val.equals("no")))).toString();
            } else {
                System.out.println("WARNING: queue.generateData() found bad property " + dec.getProperty() + " on Decision id=" + dec.getId());
            }
        }
        for (String mid : dataMap.keySet()) {
            rows.add(dataMap.get(mid));
//System.out.println(String.join("|", dataMap.get(mid)));
        }
    }

    ExportExcelFile.quickExcel(rows, file);
}

%>
<%

//setup our Properties object to hold all properties
String langCode = ServletUtilities.getLanguageCode(request);
String context = ServletUtilities.getContext(request);
//Properties props=ShepherdProperties.getProperties("whoweare.properties", langCode, context);
request.setAttribute("pageTitle", "Kitizen Science &gt; Queue");
Shepherd myShepherd = new Shepherd(context);
myShepherd.setAction("queue.jsp");
myShepherd.beginDBTransaction();
User user = AccessControl.getUser(request, myShepherd);
if (user == null) {
    myShepherd.rollbackDBTransaction();
    response.sendRedirect("login.jsp");
    return;
}

String[] validRoles = new String[]{"admin", "super_volunteer", "cat_mouse_volunteer", "cat_walk_volunteer"};
List<Role> userRoles = myShepherd.getAllRolesForUserInContext(user.getUsername(), context);
String maxRole = null;
foundMaxRole:
for (String vr : validRoles) {
    for (Role r : userRoles) {
        if (vr.equals(r.getRolename())) {
            maxRole = vr;
            break foundMaxRole;
        }
    }
}
System.out.println("INFO: queue.jsp maxRole=" + maxRole + " for " + user);

//maxRole = "cat_mouse_volunteer";  //faked for testing
//TODO what to do about cat_walk_volunteer ???
if (maxRole == null) {
    //response.sendError(401, "access denied - no valid role");
    myShepherd.rollbackDBTransaction();
    response.sendRedirect("register.jsp");
    return;
}

boolean isAdmin = (maxRole.equals("super_volunteer") || maxRole.equals("admin"));
boolean forceList = Util.requestParameterSet(request.getParameter("forceList")) || isAdmin;

String dtype = request.getParameter("data");
if (Util.requestParameterSet(dtype)) {
    File xls = new File("/tmp/kitsci_export_" + Util.basicSanitize(dtype) + "_" + new DateTime().toLocalDate() + "_" + Util.generateUUID().substring(0,6) + ".xls");
    generateData(myShepherd, xls, dtype);
    response.setHeader("Content-type", "application/vnd.ms-excel");
    response.setHeader("Content-disposition", "attachment; filename=\"" + xls.getName() + "\"");
    FileUtils.copyFile(xls, response.getOutputStream());
    return;
}

String jdoql = "SELECT FROM org.ecocean.Encounter";
if (!isAdmin) jdoql = "SELECT FROM org.ecocean.Encounter WHERE state=='processing'";
Query query = myShepherd.getPM().newQuery(jdoql);
query.setOrdering("state, dateInMilliseconds");
Collection col = (Collection)query.execute();
List<Encounter> encs = new ArrayList<Encounter>(col);
query.closeAll();

if (!isAdmin) {   //filter out ones we made decision on
    Iterator it = encs.iterator();
    while (it.hasNext()) {
        Encounter e = (Encounter)it.next();
        jdoql = "SELECT FROM org.ecocean.Decision WHERE encounter.catalogNumber=='" + e.getCatalogNumber() + "' && user.uuid=='" + user.getUUID() + "'";
        query = myShepherd.getPM().newQuery(jdoql);
        col = (Collection)query.execute();
        //List<Decision> decs = new ArrayList<Decision>(col);
        int decCt = col.size();
        query.closeAll();
        if (decCt > 0) it.remove();
    }
}

System.out.println("queue.jsp: found " + encs.size() + " encs for user " + user);

if (!forceList && (encs.size() > 0)) {
    String redir = "encounters/encounterDecide.jsp?id=" + encs.get(0).getCatalogNumber();
    myShepherd.rollbackDBTransaction();
    response.sendRedirect(redir);
    return;
}

String[] theads = new String[]{"ID", "Sub Date"};
if (isAdmin) theads = new String[]{"ID", "State", "Cat", "MatchPhoto", "Sub Date", "Last Dec", "Dec Ct", "Flags"};
%>

<jsp:include page="header.jsp" flush="true" />
<style>
.col-matchphoto-0 {
    background-color: #FFA;
}
.col-matchphoto-2,
.col-matchphoto-3,
.col-matchphoto-4,
.col-matchphoto-5 {
    background-color: #DDD;
}
.col-flag {
    background-color: #FAA;
}
.col-fct-0, .col-dct-0, .col-muted {
    color: #BBB;
    background-color: inherit;
}

.col-id {
    position: relative;
}
.col-id img {
    height: 50px;
    float: right;
}
.th-0, .th-1 {
    width: 8em;
}
.th-2, .th-3 {
    width: 12em;
}
.th-4, .th-5 {
    width: 4em;
}

#filter-tabs button {
    font-size: 0.9em;
    font-weight: bold;
    margin: 10px;
}
#filter-tabs button.tab-active {
    background-color: #FFA;
    color: black;
    outline: 1px solid green;
}

/* default is off for all but pending currently */
.row-state-pending,
.row-state-rejected,
.row-state-disputed,
.row-state-processing,
.row-state-finished,
.row-state-practice,
.row-state-unapproved,
.row-state-approved {
    display: none;
}

#filter-info {
    margin-left: 20px;
}

#filter-tabs .fct {
    font-size: 0.85em;
    opacity: 0.6;
    margin-left: 10px;
}

</style>


<div class="container maincontent">
<!-- main role: <%=maxRole%> -->

<% if (isAdmin) { %>
<p>
    <a href="queue.jsp?data=attributes" title="Download XLS with volunteer decisions on attributes">
        <button>Download Attributes XLS</button>
    </a>
    <a href="queue.jsp?data=match" title="Download XLS with volunteer cat ID matches">
        <button>Download ID Match XLS</button>
    </a>
</p>
<div id="filter-tabs">
    <button id="filter-button-incoming" onClick="return filter('incoming');">incoming<span class="fct"></span></button>
    <button id="filter-button-pending" onClick="return filter('pending');">pending<span class="fct"></span></button>
    <button id="filter-button-processing" onClick="return filter('processing');">processing<span class="fct"></span></button>
    <button id="filter-button-finished" onClick="return filter('finished');">finished<span class="fct"></span></button>
    <button id="filter-button-flagged" onClick="return filter('flagged');">flagged<span class="fct"></span></button>
    <button id="filter-button-disputed" onClick="return filter('disputed');">disputed<span class="fct"></span></button>
    <button id="filter-button-rejected" onClick="return filter('rejected');">rejected<span class="fct"></span></button>
    <span id="filter-info"></span>
</div>
<% } %>

<% if (encs.size() < 1) { %>
    <h1>There are no submissions needing attention right now!</h1>

<% } else { %>
<table id="queue-table" xdata-page-size="6" data-height="650" data-toggle="table" data-pagination="false">
<thead>
<tr>
<% for (int ci = 0 ; ci < theads.length ; ci++) { %>
    <th <%=((ci == 0 || ci == 2 || ci == 3 || ci == 7) ? "data-sorter=\"ahrefSort\"" : "")%> class="th-<%=ci%>" data-sortable="true"><%=theads[ci]%></th>
<% } %>
</tr>
</thead>
<tbody>
<%
    for (Encounter enc : encs) {
        out.println("<tr class=\"enc-row row-state-" + enc.getState() + "\">");
        String ename = enc.getEventID();
        if (ename == null) ename = enc.getCatalogNumber().substring(0,8);
        out.println("<td class=\"col-id\">");
        if (isAdmin) {
            out.println("<a href=\"encounters/encounter.jsp?number=" + enc.getCatalogNumber() + "\" target=\"new\">" + ename + "</a>");
        } else {
            out.println("<a href=\"encounters/encounterDecide.jsp?id=" + enc.getCatalogNumber() + "\" target=\"new\">" + ename + "</a>");
        }
/*
        if (enc.getMedia().size() > 0) {
            out.println("<img src=\"" + enc.getMedia().get(0).safeURL(request) + "\" />");
        }
*/
        out.println("</td>");
        if (isAdmin) {
            int ct = -1;
            String indivId = null;
            String indivName = null;
            String matchphotoNote = "-";
            if (enc.hasMarkedIndividual()) {
                indivName = enc.getDisplayName();
                if (indivName == null) indivName = enc.getIndividual().getId().substring(0,6);
                indivId = enc.getIndividual().getId();
                ct = Util.collectionSize(getMatchPhotoAnnotations(myShepherd, enc.getIndividual()));
            }
%><td class="col-state-<%=enc.getState()%>"><%=enc.getState()%></td>
<td><a target="_new" <%=((indivId == null) ? "" : "href=\"individuals.jsp?number=" + indivId + "\"")%>><%=indivName%></a></td>
<td class="col-matchphoto-<%=ct%>"><a target="_new" <%=((ct < 0) ? "" : "href=\"individualGallery.jsp?id=" + indivId + "\"")%>><%=((ct < 0) ? "-" : ct)%></a></td><%
        }
        out.println("<td>" + enc.getDate() + "</td>");

        if (isAdmin) {
            jdoql = "SELECT FROM org.ecocean.Decision WHERE encounter.catalogNumber=='" + enc.getCatalogNumber() + "'";
            query = myShepherd.getPM().newQuery(jdoql);
            col = (Collection)query.execute();
            List<Decision> decs = new ArrayList<Decision>(col);
            query.closeAll();
            int dct = 0;
            int fct = 0;
            long lastT = 0L;
            Map<String,Integer> fmap = new HashMap<String,Integer>();
            for (Decision dec : decs) {
                if ("sex".equals(dec.getProperty())) dct++;
                if ("flag".equals(dec.getProperty())) {
                    fct++;
                    if (dec.getValue() != null) {
                        JSONArray vals = dec.getValue().optJSONArray("value");
                        if (vals != null) {
                            for (int i = 0 ; i < vals.length() ; i++) {
                                String fval = vals.optString(i, null);
                                if (fval != null) {
                                    if (fmap.get(fval) == null) fmap.put(fval, 0);
                                    fmap.put(fval, fmap.get(fval) + 1);
                                }
                            }
                        }
                    }
                }
                if (dec.getTimestamp() > lastT) lastT = dec.getTimestamp();
            }
            if (lastT > 0L) {
                //out.println("<td class=\"col-muted\">9999</td>");
                out.println("<td class=\"col-date\">" + new DateTime(lastT).toLocalDate() + "</td>");
            } else {
                out.println("<td class=\"col-muted\">-</td>");
            }
            out.println("<td class=\"col-dct-" + dct + "\">" + dct + "</td>");
            out.println("<td " + ((fct == 0) ? "" : " title=\"" + String.join(" | ", fmap.keySet()) + "\"") + " class=\"col-flag" + ((fct > 0) ? " is-flagged" : "") + " col-fct-" + fct + "\">" + fct + "</td>");
        }

        out.println("</tr>");
    }
%>
</tbody>
</table>

<% } //table %>

</div>

    <script src="javascript/bootstrap-table/bootstrap-table.min.js"></script>
    <link rel="stylesheet" href="javascript/bootstrap-table/bootstrap-table.min.css" />
<script>
function ahrefSort(a, b) {
    var valA = $(a).text();
    if (!valA.length) valA = a;
    var valB = $(b).text();
    if (!valB.length) valB = b;
    return valA.localeCompare(valB);
}
var currentActiveState = 'incoming';
$(document).ready(function() {
    setActiveTab(currentActiveState);
    $('#queue-table').on('post-body.bs.table', function() {
        filter(currentActiveState);
    });
/*
    $('.col-flag').each(function(i, el) {
        var jel = $(el);
//console.log('%d %o %o %o', i, el, el.parentElement, jel.text());
        if (jel.text() > 0) jel.parent().show();
    });
*/

    $('#filter-tabs button').each(function(i,el) {
        var state = el.id.substring(14);
        var ct = $('.enc-row.row-state-' + state).length;
        if (state == 'flagged') ct = $('.is-flagged').length;
        $(el).find('.fct').html(ct);
    });
});

function setActiveTab(state) {
    $('#filter-tabs .tab-active').removeClass('tab-active');
    $('#filter-button-' + state).addClass('tab-active');
    var ct = $('.enc-row:visible').length;
    $('#filter-info').html('<b>' + ct + '</b> <i>' + state + '</i> submission' + (ct == 1 ? '' : 's'));
}

function filter(state) {
    currentActiveState = state;
    $('.enc-row').hide();
    $('.row-state-' + state).show();

    if (state == 'flagged') {  //special case to find also *any* with flags
        $('.is-flagged').each(function(i, el) {
            $(el).parent().show();
        });
/*
        $('.col-flag').each(function(i, el) {
            var jel = $(el);
//console.log('%d %o %o %o', i, el, el.parentElement, jel.text());
            if (jel.text() > 0) jel.parent().show();
        });
*/
    }

    setActiveTab(state);
}

</script>


<jsp:include page="footer.jsp" flush="true" />

<%
myShepherd.rollbackDBTransaction();
%>
