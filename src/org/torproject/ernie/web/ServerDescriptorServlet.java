package org.torproject.ernie.web;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.*;
import java.math.*;
import java.text.*;
import java.util.*;
import java.util.regex.*;

public class ServerDescriptorServlet extends HttpServlet {

  public void doGet(HttpServletRequest request,
      HttpServletResponse response) throws IOException,
      ServletException {

    String descIdParameter = request.getParameter("desc-id");

    /* Check if we have a descriptors directory. */
    // TODO make this configurable!
    File archiveDirectory = new File("/srv/metrics.torproject.org/ernie/"
        + "directory-archive/server-descriptor");
    if (!archiveDirectory.exists() || !archiveDirectory.isDirectory()) {
      /* Oops, we don't have any descriptors to serve. */
      response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
      return;
    }

    /* Check desc-id parameter. */
    if (descIdParameter == null || descIdParameter.length() < 4) {
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      return;
    }
    String descId = descIdParameter.toLowerCase();
    Pattern descIdPattern = Pattern.compile("^[0-9a-f]+$");
    Matcher descIdMatcher = descIdPattern.matcher(descId);
    if (!descIdMatcher.matches()) {
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      return;
    }

    for (File yearFile : archiveDirectory.listFiles()) {
      for (File monthFile : yearFile.listFiles()) {
        File subDirectory = new File(monthFile.getAbsolutePath() + "/"
            + descId.substring(0, 1) + "/" + descId.substring(1, 2));
        if (subDirectory.exists()) {
          for (File serverDescriptorFile : subDirectory.listFiles()) {
            if (!serverDescriptorFile.getName().startsWith(descId)) {
              continue;
            }

            /* Found it! Read file from disk and write it to response. */
            BufferedInputStream input = null;
            BufferedOutputStream output = null;
            try {
              response.setContentType("text/plain");
              response.setHeader("Content-Length", String.valueOf(
                  serverDescriptorFile.length()));
              response.setHeader("Content-Disposition",
                  "inline; filename=\"" + serverDescriptorFile.getName()
                  + "\"");
              input = new BufferedInputStream(new FileInputStream(
                  serverDescriptorFile), 1024);
              output = new BufferedOutputStream(
                  response.getOutputStream(), 1024);
              byte[] buffer = new byte[1024];
              int length;
              while ((length = input.read(buffer)) > 0) {
                  output.write(buffer, 0, length);
              }
            } finally {
              output.close();
              input.close();
            }
          }
        }
      }
    }

    /* Not found. */
    response.setStatus(HttpServletResponse.SC_NOT_FOUND);
  }
}

