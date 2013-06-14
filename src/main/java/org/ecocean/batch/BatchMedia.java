package org.ecocean.batch;

import java.util.Arrays;

/**
 * Represents a media item for an encounter, and only used during batch data
 * processing as a data-holding intermediary.
 *
 * @author Giles Winstanley
 */
public class BatchMedia {
  /** EventID for item (links to an encounter in CSV file). */
  private String eventID;
  /** URL from which media item can be downloaded. */
  private String mediaURL;
  /** Copyright owner string. */
  private String copyrightOwner;
  /** Copyright statement string. */
  private String copyrightStatement;
  /** Array of media keywords. */
  private String[] keywords;
  /** Flag indicating whether item has been downloaded. */
  private boolean downloaded;
  /** Flag indicating whether item has been assigned to an encounter. */
  private boolean assigned;
  /** Flag indicating whether item should be persisted to database. */
  private boolean persist = true;

  public BatchMedia(String eventID, String mediaURL, String copyrightOwner, String copyrightStatement) {
    this.eventID = eventID;
    this.mediaURL = mediaURL;
    this.copyrightOwner = copyrightOwner;
    this.copyrightStatement = copyrightStatement;
  }

  public BatchMedia() {
  }

  public String getEventID() {
    return eventID;
  }

  public void setEventID(String eventID) {
    this.eventID = eventID;
  }

  public String getMediaURL() {
    return mediaURL;
  }

  public void setMediaURL(String mediaURL) {
    this.mediaURL = mediaURL;
  }

  public String getCopyrightOwner() {
    return copyrightOwner;
  }

  public void setCopyrightOwner(String copyrightOwner) {
    this.copyrightOwner = copyrightOwner;
  }

  public String getCopyrightStatement() {
    return copyrightStatement;
  }

  public void setCopyrightStatement(String copyrightStatement) {
    this.copyrightStatement = copyrightStatement;
  }

  public String[] getKeywords() {
    return (keywords == null) ? null : Arrays.copyOf(keywords, keywords.length);
  }

  public void setKeywords(String[] keywords) {
    this.keywords = keywords;
  }

  public boolean isDownloaded() {
    return downloaded;
  }

  public void setDownloaded(boolean downloaded) {
    this.downloaded = downloaded;
  }

  public boolean isAssigned() {
    return assigned;
  }

  public void setAssigned(boolean assigned) {
    this.assigned = assigned;
  }

  public boolean isPersist() {
    return persist;
  }

  public void setPersist(boolean persist) {
    this.persist = persist;
  }
}
